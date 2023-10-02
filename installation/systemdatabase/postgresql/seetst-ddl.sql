-- TEMPLATE - make sure to edit names (database, schema, runtime_user)
--
-- seetst-ddl.sql - Create SEEBURGER BIS 6.7 database on PostgreSQL
--
-- Revision: 2023-06-16
--
-- Copyright 2021-2023 SEEBURGER AG, Germany. All rights reserved.

\set ON_ERROR_STOP on
\set ECHO errors
\set QUIET off
\connect

-- modify this section for your object names
\set database seetst
\set schema seeasdb0
\set runtime_user seerun0
-- adjust "collation" if PostgreSQL server runs on Windows: use 'English_United States.1252'
\set collation 'en_US.UTF8'

-- asks for user input of new passwords, you can use \set to define them here
\echo Creating Database=:database with Schema=:schema and runtime_user=:runtime_user
\prompt 'Enter new owner - user password: ' owner_pass
\prompt 'Enter new runtime-user password: ' runtime_pass


-- dependent variables, do not modify
\set owner_user :schema
-- remove possible @domain from admin user (Azure)
SELECT substring(:'USER' from '[^@]+') as ladmin;
\gset

-- optionally if you have special tablespace folder, add "TABLESPACE 'seedta'"
CREATE DATABASE :database
  WITH
    ENCODING 'UTF8'
    LC_COLLATE :'collation'
    LC_CTYPE :'collation'
    TEMPLATE 'template0';
COMMENT ON DATABASE :database
  IS 'SEEBURGER BIS database';

-- if you do not use dedicated runtime user,
-- remove "CONNECTION LIMIT 10" clause
CREATE USER :owner_user LOGIN PASSWORD :'owner_pass' CONNECTION LIMIT 10;
COMMENT ON ROLE :owner_user
  IS 'SEEBURGER BIS schema owner user';

ALTER ROLE :owner_user IN DATABASE :database SET search_path = :schema;

CREATE USER :runtime_user LOGIN PASSWORD :'runtime_pass';
COMMENT ON ROLE :runtime_user
  IS 'SEEBURGER BIS runtime user';

ALTER ROLE :runtime_user IN DATABASE :database SET search_path = :schema;

GRANT CONNECT ON DATABASE :database TO :runtime_user,:owner_user;

\connect :database

-- This is required if your admin user has no superuser attribute
GRANT :owner_user TO :ladmin;

CREATE SCHEMA IF NOT EXISTS :schema AUTHORIZATION :owner_user;
COMMENT ON SCHEMA :schema
  IS 'SEEBURGER BIS schema';

-- the following allows seerun0 to use all future schema objects
GRANT USAGE ON SCHEMA :schema TO :runtime_user;
ALTER DEFAULT PRIVILEGES FOR ROLE :owner_user IN SCHEMA :schema
  GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE ON TABLES TO :runtime_user;
ALTER DEFAULT PRIVILEGES FOR ROLE :owner_user IN SCHEMA :schema
  GRANT EXECUTE ON FUNCTIONS TO :runtime_user;

-- the following adds grants to existing objects (in addition to defaults):
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE
  ON ALL TABLES IN SCHEMA :schema TO :runtime_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA :schema TO :runtime_user;

-- public has no access
REVOKE ALL ON DATABASE :database FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE :owner_user IN SCHEMA :schema
  REVOKE SELECT ON TABLES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES FOR ROLE :owner_user
  REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

-- if extension is not created diffdb will try to create it, which will not work due to permissions
-- Since you can register the extension only once per DB, make sure each BIS schema has its own database
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA :schema;
COMMENT ON EXTENSION "uuid-ossp"
  IS 'SEEBURGER BIS uses this in vUUID';

\connect postgres

\echo Reached end of script.
