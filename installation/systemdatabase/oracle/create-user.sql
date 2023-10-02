-- create-user.sql - Create Runtime User for SEEBURGER BIS 6.7 on Oracle DB
--
-- Revision: 2020-05-22
--
-- Copyright 2010-2023 SEEBURGER AG, Germany. All rights reserved.

-- This sample script creates a user named "SEERUN0".
-- This script depends on tablespace "SEEDTA"
-- This script depends on role "SEECONNECT"
-- This script depends on profile "SEERUNTIME"

-- You need to be connected to a non-CDB or correct PDB
-- PDBSEEBIS is the sample name for a plugable database
-- ALTER SESSION SET CONTAINER="PDBSEEBIS";

-- You need to run this as DBA
SET ROLE "DBA";

-- Create User
-- (use a random passwords compliant to complexity rules - minimum 12 characters)
CREATE USER "SEERUN0" IDENTIFIED BY "secret"
  DEFAULT TABLESPACE "SEEDTA"
  PROFILE "SEERUNTIME";

-- Assign Roles
GRANT "SEECONNECT" TO "SEERUN0";
ALTER USER "SEERUN0" DEFAULT ROLE "SEECONNECT";

-- Make sure to use owner's schema after login
CREATE or REPLACE TRIGGER "SEERUN0".AFTER_LOGON_TRG AFTER LOGON ON "SEERUN0".SCHEMA
  BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET current_schema="SEEASDB0"';
  END;
/

-- end of script
