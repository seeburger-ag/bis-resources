-- create-roles.sql - Create Roles for SEEBURGER BIS 6.7 on Oracle DB
--
-- Revision: 2023-04-17
--
-- Copyright 2010-2023 SEEBURGER AG, Germany. All rights reserved.

-- You need to be connected to a non-CDB or correct PDB
-- PDBSEEBIS is the sample name for a plugable database
-- ALTER SESSION SET CONTAINER="PDBSEEBIS";

-- You need to run this as DBA
SET ROLE "DBA";

-- Needed for Runtime
CREATE ROLE "SEECONNECT";

GRANT CREATE SESSION TO "SEECONNECT";
-- For JDBC Recovery
GRANT FORCE TRANSACTION TO "SEECONNECT";
GRANT SELECT ON sys.dba_pending_transactions TO "SEECONNECT";
GRANT SELECT ON sys.pending_trans$ TO "SEECONNECT";
GRANT SELECT ON sys.dba_2pc_pending TO "SEECONNECT";

-- comment out the following line on Amazon RDS
GRANT EXECUTE ON sys.dbms_xa TO "SEECONNECT";

-- Two more grants are to be added for Transaction Recovery Manager
-- when "ORA-01031: insufficient privileges" constantly appears
-- WARNING: this could also mean you use unsupported drivers or db server
-- in this case do not GRANT the following two privs, but fix the installation
-- GRANT SELECT ANY TRANSACTION TO "SEECONNECT";
-- GRANT FORCE ANY TRANSACTION TO "SEECONNECT";

-- used by DBSpaceMonitor
GRANT SELECT ON sys.dba_data_files TO "SEECONNECT";
GRANT SELECT ON sys.dba_users TO "SEECONNECT";
GRANT SELECT ON sys.dba_free_space TO "SEECONNECT";
-- used by DBSpaceMonitor (via PUBLIC)
GRANT SELECT ON sys.v_$parameter TO "SEECONNECT";

-- comment out the following line on Amazon RDS
GRANT SELECT ON sys.v_$version TO "SEECONNECT";

-- For logon trigger of runtime user
GRANT ALTER SESSION TO "SEECONNECT";
GRANT EXECUTE ON sys.dbms_application_info TO "SEECONNECT";

-- Needed to setup the Schema Objects
CREATE ROLE "SEERESOURCE";

GRANT CREATE TABLE TO "SEERESOURCE";
GRANT CREATE VIEW TO "SEERESOURCE";
GRANT CREATE PROCEDURE TO "SEERESOURCE";
-- optional
GRANT CREATE TYPE TO "SEERESOURCE";
GRANT CREATE TRIGGER TO "SEERESOURCE";
GRANT CREATE SYNONYM TO "SEERESOURCE";
GRANT CREATE MATERIALIZED VIEW TO "SEERESOURCE";
-- Allows troubleshooting
GRANT SELECT_CATALOG_ROLE TO "SEERESOURCE";
-- Allow diffdb apply to validate views (granted by PUBLIC)
-- GRANT EXECUTE on sys.DBMS_UTILITY TO "SEERESOURCE";

-- Limited restrictions for application users
CREATE PROFILE "SEERUNTIME" LIMIT
  PASSWORD_LIFE_TIME 370 PASSWORD_GRACE_TIME unlimited
  FAILED_LOGIN_ATTEMPTS 100 PASSWORD_LOCK_TIME 1/288
  PASSWORD_ROLLOVER_TIME 3
  COMPOSITE_LIMIT unlimited
  SESSIONS_PER_USER unlimited
  CPU_PER_SESSION unlimited
  CPU_PER_CALL unlimited
  LOGICAL_READS_PER_SESSION unlimited
  LOGICAL_READS_PER_CALL unlimited
  IDLE_TIME unlimited
  CONNECT_TIME unlimited
  PRIVATE_SGA unlimited;

-- end of script
