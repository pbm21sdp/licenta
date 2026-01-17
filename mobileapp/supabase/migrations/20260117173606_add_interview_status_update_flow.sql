-- Add 'interview' status to application_status enum
ALTER TYPE application_status ADD VALUE IF NOT EXISTS 'interview';

-- Update generate_notification_content function to handle interview status
CREATE OR REPLACE FUNCTION public.generate_notification_content(
    p_old_status application_status,
    p_new_status application_status,
    p_pet_name text
)
RETURNS TABLE(title text, message text)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN QUERY
    SELECT
        CASE p_new_status
            WHEN 'under_review'::public.application_status THEN 'Application Under Review'
            WHEN 'interview'::public.application_status THEN '📅 Interview Scheduled'
            WHEN 'approved'::public.application_status THEN '🎉 Application Approved!'
            WHEN 'rejected'::public.application_status THEN 'Application Update'
            WHEN 'withdrawn'::public.application_status THEN 'Application Withdrawn'
            ELSE 'Application Status Changed'
        END::TEXT,
        CASE p_new_status
            WHEN 'under_review'::public.application_status THEN 
                'Your application for ' || p_pet_name || ' is now being reviewed by the shelter.'
            WHEN 'interview'::public.application_status THEN 
                'Great news! The shelter wants to schedule an interview for ' || p_pet_name || '. They will contact you soon with available times.'
            WHEN 'approved'::public.application_status THEN 
                'Congratulations! Your application for ' || p_pet_name || ' has been approved. The shelter will contact you soon with next steps.'
            WHEN 'rejected'::public.application_status THEN 
                'Unfortunately, your application for ' || p_pet_name || ' was not approved this time. Please check the application details for more information.'
            WHEN 'withdrawn'::public.application_status THEN 
                'Your application for ' || p_pet_name || ' has been withdrawn.'
            ELSE 'Status changed from ' || p_old_status::TEXT || ' to ' || p_new_status::TEXT
        END::TEXT;
END;
$$;