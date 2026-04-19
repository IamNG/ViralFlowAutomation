-- Enable pg_net and pg_cron to allow HTTP requests from the DB to Edge Functions
CREATE EXTENSION IF NOT EXISTS pg_net;
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Set up the cron job to call the auto-publish function every minute
-- Note: Replace 'https://[PROJECT-REF].functions.supabase.co/auto-publish' with actual project URL
SELECT cron.schedule(
  'auto-publish-job',
  '* * * * *',
  $$
    SELECT net.http_post(
      url:='https://[PROJECT-REF].functions.supabase.co/auto-publish',
      headers:='{"Content-Type": "application/json", "Authorization": "Bearer [ANON_KEY]"}'::jsonb,
      body:='{}'::jsonb
    ) as request_id;
  $$
);
