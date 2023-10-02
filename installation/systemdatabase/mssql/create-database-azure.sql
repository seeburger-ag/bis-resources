-- TEMPLATE - please edit database/owner user name (SEEASDB0)
--                        and database sizing parameters (beware cost!)
--
-- create-database-azure.sql - Create Database for BIS 6.7 on Azure SQL Database
--
-- Revision 2021-03-31
--
-- You can execute this script in SSMS when enabling Query->sqlcmd mode
--
-- Copyright 2020-2023 SEEBURGER AG, Germany. All rights reserved.
:on error exit

-- configure database name (will be used as owner user name as well)
:setvar dbname SEEASDB0
GO

USE [master];
GO

-- first check database (DO NOT CHANGE)
declare @u varchar(10) = 'UNKNOWN';
declare @ver varchar(20) = isnull(convert(char(30),serverproperty('ProductVersion')),@u);
declare @inst nvarchar(128) = isnull(convert(nvarchar(128),serverproperty('ServerName')),@u);
declare @edition nvarchar(128) = isnull(convert(nvarchar(128), serverproperty('Edition')),@u);
declare @btype varchar(5) = convert(char(5),serverproperty('ProductBuildType'));
declare @edid int = isnull(convert(int,serverproperty('EditionID')), 0);
declare @eed int = isnull(convert(int, serverproperty('EngineEdition')), 0);
declare @sub varchar(5) = substring(@ver,1,5);
print 'Instance: ' + @inst;
print 'Version : ' + @ver + ' Edition: ' + @edition;
print '';
if (@btype <> 'GDR')
BEGIN print 'WARNING: Product Buildtype is not generally delivery productBuildType='+@btype; END
if (@edid = 610778273 OR @edid = -2117995310)
BEGIN print 'WARNING: Edition might not be licensed for production use ('+convert(nvarchar,@edid)+').'; END
if (@eed <> 5)
BEGIN print 'WARNING: Edition is not supported for full production use.'; END
if (@sub <> '12.0.')
BEGIN raiserror('FATAL: Not a supported SQL Server version.', 18, 1); END
GO

-- Create Database

print 'Creating database $(dbname)';
GO

-- make sure to configure MAXSIZE, Service_Objective and Edition according to your sizing
-- https://docs.microsoft.com/en-us/sql/t-sql/statements/create-database-transact-sql?view=azuresqldb-current
CREATE DATABASE [$(dbname)]
  COLLATE SQL_Latin1_General_CP1_CI_AS
  ( MAXSIZE = 1024 GB,  EDITION = 'BusinessCritical', SERVICE_OBJECTIVE = 'BC_GEN5_8' )
  WITH BACKUP_STORAGE_REDUNDANCY =  'LOCAL';
GO

print 'Database created.';
GO
-- end of script
