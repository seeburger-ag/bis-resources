-- grant-runtime-user.sql - Grant runtime permissions for SEEBURGER BIS 6.7 on Oracle DB
--
-- Revision: 2020-05-25
--
-- Copyright 2010-2023 SEEBURGER AG, Germany. All rights reserved.

-- You need to be connected to a non-CDB or correct PDB
-- PDBSEEBIS is the sample name for a plugable database
-- ALTER SESSION SET CONTAINER="PDBSEEBIS";

-- run this as SEEASDB0 (owner user)
-- change SEERUN0B to the actual target runtime user

BEGIN
    FOR i IN (SELECT table_name FROM user_tables) LOOP
        EXECUTE IMMEDIATE 'grant select, insert, update, delete on "' || i.table_name || '" to "SEERUN0B"';
    END LOOP;
    FOR i IN (SELECT view_name FROM user_views) LOOP
        EXECUTE IMMEDIATE 'grant select, insert, update, delete on "' || i.view_name || '" to "SEERUN0B"';
    END LOOP;
    FOR i IN (SELECT object_name FROM user_procedures WHERE object_type IN ('FUNCTION','PROCEDURE') ) LOOP
        EXECUTE IMMEDIATE 'grant execute on "' || i.object_name || '" to "SEERUN0B"';
    END LOOP;
END;
/

-- end of script
