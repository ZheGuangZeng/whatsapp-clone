create schema if not exists webhooks;

create table if not exists webhooks.http_request_queue (
  id bigserial primary key,
  method text not null,
  url text not null,
  headers jsonb,
  body text,
  timeout_milliseconds integer
);