-- Create roles
create role anon;
create role authenticated;
create role service_role;
create role supabase_admin;
create role supabase_auth_admin;
create role supabase_storage_admin;

-- Grant permissions
grant usage on schema public to anon;
grant usage on schema public to authenticated;
grant usage on schema public to service_role;

grant all on all tables in schema public to service_role;
grant all on all sequences in schema public to service_role;
grant all on all functions in schema public to service_role;

-- Auth admin permissions
grant all on schema auth to supabase_auth_admin;
grant all on all tables in schema auth to supabase_auth_admin;
grant all on all sequences in schema auth to supabase_auth_admin;