-- Create BIS maintenance role on PostgreSQL TEMPLATE
-- Revision: 2026-08-07
-- (c) Copyright 2026 SEEBURGER AG, Germany. All rights reserved.

-- if you need to revert this script:
-- \c seetst
-- REVOKE CONNECT ON DATABASE seetst FROM seeasdb0_maint;
-- REVOKE USAGE ON SCHEMA seeasdb0 FROM seeasdb0_maint;
-- ALTER DEFAULT PRIVILEGES FOR ROLE seeasdb0 IN SCHEMA seeasdb0 REVOKE ALL ON TABLES FROM seeasdb0_maint;
-- DROP ROLE seeasdb0_maint;

\set ON_ERROR_STOP on
\set ECHO errors
\set QUIET off
\connect

-- modify this section for your object names
\set database seetst
\set schema seeasdb0


-- dependent variables, do not modify
\set owner_user :schema
-- if schema is 'seeasdb0', maintenance role will be 'seeasdb0_maint'
\set maint_role :schema'_maint'

CREATE ROLE :maint_role NOLOGIN NOINHERIT CONNECTION LIMIT 10;
COMMENT ON ROLE :maint_role
 IS 'SEEBURGER BIS schema maintenance role';

-- not used by login but by SET ROLE
ALTER ROLE :maint_role IN DATABASE :database SET search_path = :schema;
ALTER ROLE :maint_role IN DATABASE :database SET work_mem = '16MB';
ALTER ROLE :maint_role IN DATABASE :database SET maintenance_work_mem = '128MB';

-- might need duplication if user is NOINHERIT
GRANT CONNECT ON DATABASE :database TO :maint_role;

\connect :database
SET ROLE :owner_user;

GRANT USAGE ON SCHEMA :schema TO :maint_role;

-- the following allows access to future and current tables
ALTER DEFAULT PRIVILEGES FOR ROLE :owner_user IN SCHEMA :schema
 GRANT MAINTAIN ON TABLES TO :maint_role;

-- the following adds grants to existing objects (in addition to defaults):
GRANT MAINTAIN ON ALL TABLES IN SCHEMA :schema TO :maint_role;

RESET ROLE
\connect postgres

-- to use the role with a new user:
-- CREATE USER maint_user LOGIN NOINHERIT IN ROLE seeasdb_maint;
-- -or- GRANT seeasb0_maint TO maint_user;
-- GRANT CONNECT ON DATABASE seetst TO maint_user;
-- SET ROLE seeasdbo_maint; -- to activate the role in the session

\echo Reached end of script.
