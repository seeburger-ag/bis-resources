-- TEMPLATE - please edit names (SEEASDB0, SEERUN0) and password
--
-- create-user.sql - Create users for BIS 6.7 on SQL Server
--
-- Revision 2020-05-20
--
-- You can execute this script in SSMS when enabling Query->sqlcmd mode
--
-- Copyright 2010-2023 SEEBURGER AG, Germany. All rights reserved.
:on error exit

-- configure names, password and location
:setvar dbname SEEASDB0
:setvar runtimeuser SEERUN0
:setvar runpass secret

GO

USE [master];

-- create login for runtime user
CREATE LOGIN [$(runtimeuser)] WITH PASSWORD=N'$(runpass)', CHECK_EXPIRATION=OFF,
  DEFAULT_DATABASE=[$(dbname)], DEFAULT_LANGUAGE=us_english;

-- Permissions needed if you want to use the BIS db space monitor (sys.master_files,dm_os_volume_stats)
GRANT VIEW SERVER STATE TO [$(runtimeuser)];
GRANT VIEW ANY DEFINITION TO [$(runtimeuser)];

GO

USE [$(dbname)];

-- create runtime user and assign permissions
CREATE USER [$(runtimeuser)] FOR LOGIN [$(runtimeuser)] WITH DEFAULT_SCHEMA=[dbo];
ALTER ROLE db_datareader ADD MEMBER [$(runtimeuser)];
ALTER ROLE db_datawriter ADD MEMBER [$(runtimeuser)];
GRANT EXECUTE TO [$(runtimeuser)];
GRANT VIEW DATABASE STATE to [$(runtimeuser)];
GRANT SHOWPLAN to [$(runtimeuser)];

GO
print 'Finished create-user.'
GO
-- end of script
