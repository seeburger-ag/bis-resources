-- create-schema.sql - Create Schema Owner for SEEBURGER BIS 6.7 on Oracle
--
-- Revision: 2020-05-22
--
-- Copyright 2010-2023 SEEBURGER AG, Germany. All rights reserved.

-- This sample script creates a user named "SEEASDB0"
-- This script depends on roles "SEECONNECT", "SEERESOURCE"
-- This script depends on tablespaces "SEEDTA" "SEEIDX" and "SEELOB"
-- This script depends on profile "SEERUNTIME"

-- You need to be connected to a non-CDB or correct PDB
-- PDBSEEBIS is the sample name for a plugable database
-- ALTER SESSION SET CONTAINER="PDBSEEBIS";

-- You need to run this as DBA
SET ROLE "DBA";

-- Create User
-- (use a random passwords compliant to complexity rules - minimum 12 characters)
CREATE USER "SEEASDB0" IDENTIFIED BY "secret"
  DEFAULT TABLESPACE "SEEDTA"
  PROFILE "SEERUNTIME";

-- Assign Roles
GRANT "SEECONNECT" TO "SEEASDB0";
GRANT "SEERESOURCE" TO "SEEASDB0";

-- Default Assign both before install/updates
ALTER USER "SEEASDB0" DEFAULT ROLE "SEECONNECT","SEERESOURCE";

-- Allow storage in table spaces (3 Table spaces in this example)
ALTER USER "SEEASDB0" QUOTA UNLIMITED ON "SEEDTA";
ALTER USER "SEEASDB0" QUOTA UNLIMITED ON "SEEIDX";
ALTER USER "SEEASDB0" QUOTA UNLIMITED ON "SEELOB";

-- end of script
