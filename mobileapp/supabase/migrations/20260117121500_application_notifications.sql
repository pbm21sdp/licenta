-- Location: supabase/migrations/20260117121500_application_notifications.sql
-- Schema Analysis: Existing adoption_applications table with application_status and updated_at columns
-- Integration Type: Extension - Adding notification system for application status changes
-- Dependencies: adoption_applications, shelter_profiles

-- 1. Create notification_type enum
CREATE TYPE public.notification_type AS ENUM ('status_change', 'shelter_message', 'application_update');

-- 2. Create notifications table
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    application_id UUID NOT NULL REFERENCES public.adoption_applications(id) ON DELETE CASCADE,
    applicant_email TEXT NOT NULL,
    notification_type public.notification_type DEFAULT 'status_change'::public.notification_type,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    old_status public.application_status,
    new_status public.application_status,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Create indexes for efficient queries
CREATE INDEX idx_notifications_application_id ON public.notifications(application_id);
CREATE INDEX idx_notifications_email ON public.notifications(applicant_email);
CREATE INDEX idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX idx_notifications_is_read ON public.notifications(is_read);

-- 4. Enable RLS for notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policy - Users can view their own notifications
CREATE POLICY "users_view_own_notifications"
ON public.notifications
FOR SELECT
TO public
USING (true);

-- 6. Create function to generate notification content
CREATE OR REPLACE FUNCTION public.generate_notification_content(
    p_old_status public.application_status,
    p_new_status public.application_status,
    p_pet_name TEXT
) RETURNS TABLE(title TEXT, message TEXT)
LANGUAGE plpgsql
STABLE
AS $func$
BEGIN
    RETURN QUERY
    SELECT
        CASE p_new_status
            WHEN 'under_review'::public.application_status THEN 'Application Under Review'
            WHEN 'approved'::public.application_status THEN '🎉 Application Approved!'
            WHEN 'rejected'::public.application_status THEN 'Application Update'
            WHEN 'withdrawn'::public.application_status THEN 'Application Withdrawn'
            ELSE 'Application Status Changed'
        END::TEXT,
        CASE p_new_status
            WHEN 'under_review'::public.application_status THEN 
                'Your application for ' || p_pet_name || ' is now being reviewed by the shelter.'
            WHEN 'approved'::public.application_status THEN 
                'Congratulations! Your application for ' || p_pet_name || ' has been approved. The shelter will contact you soon.'
            WHEN 'rejected'::public.application_status THEN 
                'Unfortunately, your application for ' || p_pet_name || ' was not approved this time. Please check the application details for more information.'
            WHEN 'withdrawn'::public.application_status THEN 
                'Your application for ' || p_pet_name || ' has been withdrawn.'
            ELSE 'Status changed from ' || p_old_status::TEXT || ' to ' || p_new_status::TEXT
        END::TEXT;
END;
$func$;

-- 7. Create trigger function to automatically create notifications
CREATE OR REPLACE FUNCTION public.notify_application_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $trigger$
DECLARE
    v_title TEXT;
    v_message TEXT;
    notification_content RECORD;
BEGIN
    -- Only create notification if status actually changed
    IF OLD.application_status IS DISTINCT FROM NEW.application_status THEN
        -- Generate notification content
        SELECT * INTO notification_content
        FROM public.generate_notification_content(
            OLD.application_status,
            NEW.application_status,
            NEW.pet_name
        );
        
        -- Insert notification
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
            notification_content.title,
            notification_content.message,
            OLD.application_status,
            NEW.application_status
        );
    END IF;
    
    RETURN NEW;
END;
$trigger$;

-- 8. Create trigger on adoption_applications
CREATE TRIGGER trigger_notify_status_change
    AFTER UPDATE OF application_status
    ON public.adoption_applications
    FOR EACH ROW
    EXECUTE FUNCTION public.notify_application_status_change();

-- 9. Create function to mark notifications as read
CREATE OR REPLACE FUNCTION public.mark_notification_read(notification_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
BEGIN
    UPDATE public.notifications
    SET is_read = true
    WHERE id = notification_id;
END;
$func$;

-- 10. Create function to get unread notification count
CREATE OR REPLACE FUNCTION public.get_unread_notification_count(user_email TEXT)
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $func$
    SELECT COUNT(*)::INTEGER
    FROM public.notifications
    WHERE applicant_email = user_email
    AND is_read = false;
$func$;