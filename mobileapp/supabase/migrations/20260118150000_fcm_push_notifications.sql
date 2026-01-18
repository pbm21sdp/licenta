-- FCM Push Notifications Migration
-- Adds support for storing FCM tokens and sending push notifications
-- Dependencies: user_profiles, adoption_applications, notifications tables must exist

-- ============================================================================
-- FCM Tokens Table
-- ============================================================================

-- Create table for storing FCM tokens
CREATE TABLE IF NOT EXISTS fcm_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profiles(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    device_type TEXT NOT NULL CHECK (device_type IN ('android', 'ios')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    -- Each user can have multiple tokens (multiple devices)
    -- but each token should be unique per user
    UNIQUE(user_id, token)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON fcm_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_fcm_tokens_token ON fcm_tokens(token);

-- Enable RLS
ALTER TABLE fcm_tokens ENABLE ROW LEVEL SECURITY;

-- RLS Policies for fcm_tokens
-- Users can only manage their own tokens
CREATE POLICY "Users can view own tokens"
    ON fcm_tokens FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own tokens"
    ON fcm_tokens FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own tokens"
    ON fcm_tokens FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own tokens"
    ON fcm_tokens FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================================================
-- Add push_notifications_enabled to user_profiles
-- ============================================================================

ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS push_notifications_enabled BOOLEAN DEFAULT true;

-- ============================================================================
-- Function to trigger push notification via Edge Function
-- ============================================================================

-- Enable pg_net extension for HTTP calls (if not already enabled)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Function to call Edge Function for sending push notification
-- NOTE: Replace YOUR_PROJECT_REF with your actual Supabase project reference
-- The Edge Function must be deployed with --no-verify-jwt flag
CREATE OR REPLACE FUNCTION send_push_notification(
    p_user_id UUID,
    p_title TEXT,
    p_body TEXT,
    p_data JSONB DEFAULT '{}'::JSONB
) RETURNS void AS $$
BEGIN
    -- IMPORTANT: Update YOUR_PROJECT_REF with your Supabase project reference
    -- Deploy Edge Function with: supabase functions deploy send-push-notification --no-verify-jwt
    PERFORM net.http_post(
        url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-push-notification',
        headers := jsonb_build_object('Content-Type', 'application/json'),
        body := jsonb_build_object(
            'user_id', p_user_id,
            'title', p_title,
            'body', p_body,
            'data', p_data
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- Updated trigger for application status changes
-- Replaces the trigger from 20260117121500_application_notifications.sql
-- ============================================================================

-- Drop existing triggers and function (use CASCADE to handle dependencies)
DROP TRIGGER IF EXISTS on_application_status_change ON adoption_applications;
DROP TRIGGER IF EXISTS trigger_notify_status_change ON adoption_applications;
DROP FUNCTION IF EXISTS public.notify_application_status_change() CASCADE;

-- Create improved trigger function that also sends push notifications
CREATE OR REPLACE FUNCTION public.notify_application_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_notification_title TEXT;
    v_notification_body TEXT;
    v_push_enabled BOOLEAN;
    notification_content RECORD;
BEGIN
    -- Only trigger on status changes
    IF OLD.application_status IS DISTINCT FROM NEW.application_status THEN
        -- Generate notification content using existing function
        SELECT * INTO notification_content
        FROM public.generate_notification_content(
            OLD.application_status,
            NEW.application_status,
            NEW.pet_name
        );

        v_notification_title := notification_content.title;
        v_notification_body := notification_content.message;

        -- Insert in-app notification (matching existing notifications table schema)
        INSERT INTO public.notifications (
            application_id,
            applicant_email,
            notification_type,
            title,
            message,
            old_status,
            new_status
        ) VALUES (
            NEW.id,
            NEW.applicant_email,
            'status_change'::public.notification_type,
            v_notification_title,
            v_notification_body,
            OLD.application_status,
            NEW.application_status
        );

        -- Check if user has push notifications enabled
        SELECT push_notifications_enabled INTO v_push_enabled
        FROM user_profiles
        WHERE id = NEW.user_id;

        -- Send push notification if enabled (default to true if not set)
        IF COALESCE(v_push_enabled, true) = true THEN
            PERFORM send_push_notification(
                NEW.user_id,
                v_notification_title,
                v_notification_body,
                jsonb_build_object(
                    'type', 'application_update',
                    'application_id', NEW.id::TEXT,
                    'pet_id', NEW.pet_id,
                    'pet_name', NEW.pet_name,
                    'status', NEW.application_status
                )
            );
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

-- Create trigger
CREATE TRIGGER trigger_notify_status_change
    AFTER UPDATE OF application_status
    ON public.adoption_applications
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_application_status_change();
