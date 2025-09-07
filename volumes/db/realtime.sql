begin;
  create extension if not exists "uuid-ossp";
  create schema if not exists _realtime;
  create schema if not exists realtime;

  -- Realtime tables
  create table if not exists _realtime.subscription (
    id bigserial primary key,
    subscription_id uuid not null,
    entity regclass not null,
    filters realtime.user_defined_filter[] not null default '{}',
    claims jsonb not null,
    claims_role regrole not null,
    created_at timestamp without time zone default now() not null
  );
  create index if not exists subscription_subscription_id_entity_filters_idx on _realtime.subscription using btree (subscription_id, entity, filters);
  create index if not exists subscription_entity_idx on _realtime.subscription using btree (entity);

  create table if not exists _realtime.schema_migrations (
    version text primary key,
    inserted_at timestamp(0) without time zone
  );

  -- Insert schema migration
  insert into _realtime.schema_migrations (version, inserted_at)
  values ('20211116024918', now())
  on conflict (version) do nothing;

commit;