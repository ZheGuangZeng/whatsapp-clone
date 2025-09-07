create schema if not exists _analytics;

create table if not exists _analytics.logs (
  instance_id uuid,
  id uuid primary key default gen_random_uuid(),
  timestamp timestamp with time zone default now(),
  event_message text,
  metadata jsonb,
  level text,
  path text
);