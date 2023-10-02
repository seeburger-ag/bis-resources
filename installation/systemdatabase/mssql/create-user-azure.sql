-- TEMPLATE - please edit names (SEEASDB0, SEERUN0) and
--            passwords (runpass, ownpass - must be complex!)
--
-- create-users-azure.sql - Create users for BIS 6.7 on Azure SQL Database
--
-- Revision 2021-03-31
--
-- You can execute this script in SSMS when enabling Query->sqlcmd mode.
-- Make sure to connect to the target database (not master!).
--
-- Copyright 2010-2023 SEEBURGER AG, Germany. All rights reserved.
:on error exit

-- configure names and passwords
:setvar dbname SEEASDB0
:setvar runtimeuser SEERUN0
:setvar ownpass secret
:setvar runpass secret

print 'Asserting database $(dbname)'
GO

USE [$(dbname)]
GO

-- create runtime user and assign permissions
print 'Runtime: CREATE USER [$(runtimeuser)]';
CREATE USER [$(runtimeuser)] WITH DEFAULT_SCHEMA=[dbo], PASSWORD=N'$(runpass)';
ALTER ROLE db_datareader ADD MEMBER [$(runtimeuser)];
ALTER ROLE db_datawriter ADD MEMBER [$(runtimeuser)];
GRANT EXECUTE TO [$(runtimeuser)];
GRANT VIEW DATABASE STATE to [$(runtimeuser)];
GRANT SHOWPLAN to [$(runtimeuser)];
GO

-- create schema owner, must be same name as database
print 'Owner: CREATE USER [$(dbname)]';
CREATE USER [$(dbname)] WITH DEFAULT_SCHEMA=[dbo], PASSWORD=N'$(ownpass)';
ALTER ROLE db_owner ADD MEMBER [$(dbname)];
GRANT EXECUTE TO [$(dbname)];
GRANT VIEW DATABASE STATE to [$(dbname)];
GRANT SHOWPLAN to [$(dbname)];
GO

print 'Finished create-users-azure.'
GO
-- end of script
