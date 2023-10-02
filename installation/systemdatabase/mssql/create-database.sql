-- TEMPLATE - please edit datbase/owner user name (SEEASDB0),
--            directory, file sizes, file growth and password.
--
-- create-database.sql - Create Database for BIS 6.7 on SQL Server
--
-- Revision 2020-05-20
--
-- You can execute this script in SSMS when enabling Query->sqlcmd mode
-- this does NOT work for Azure SQL Database
--
-- Copyright 2010-2023 SEEBURGER AG, Germany. All rights reserved.
:on error exit

-- configure names, password and location
:setvar dbname SEEASDB0
:setvar ownpass secret
-- :setvar dir "C:\Program Files\Microsoft SQL Server\MSSQL15.PROD\MSSQL\DATA\"
-- to configue different locations for data/log see comments below

GO

USE [master];

-- first check database (DO NOT CHANGE)
declare @u varchar(10) = 'UNKNOWN';
declare @ver varchar(20) = isnull(convert(char(30),serverproperty('ProductVersion')),@u);
declare @inst nvarchar(128) = isnull(convert(nvarchar(128),serverproperty('ServerName')),@u);
declare @edition nvarchar(128) = isnull(convert(nvarchar(128), serverproperty('Edition')),@u);
declare @btype varchar(5) = convert(char(5),serverproperty('ProductBuildType'));
declare @dir nvarchar(255) = convert(nvarchar(255),serverproperty('InstanceDefaultDataPath'));
declare @edid int = isnull(convert(int,serverproperty('EditionID')), 0);
declare @eed int = isnull(convert(int, serverproperty('EngineEdition')), 0);
declare @sub varchar(5) = substring(@ver,1,5);
print 'Instance: ' + @inst + ' at ' + isnull(@dir,@u);
print 'Version : ' + @ver + ' Edition: ' + @edition;
print '';
if (@btype <> 'GDR')
BEGIN print 'WARNING: Product Buildtype is not generally delivery productBuildType='+@btype; END
if (@edid = 610778273 OR @edid = -2117995310)
BEGIN print 'WARNING: Edition might not be licensed for production use ('+convert(nvarchar,@edid)+').'; END
if (@eed <> 2 AND @eed <> 3)
BEGIN print 'WARNING: Edition is not supported for full production use.'; END
if (@sub <> '12.0.' AND @sub <> '13.0.' AND @sub <> '14.0.' AND @sub <> '15.0.')
BEGIN raiserror('FATAL: Not a supported SQL Server version.', 18, 1); END
if (@eed < 1 OR @eed > 4) BEGIN raiserror('FATAL: Not a supported product edition', 18, 2); END
GO

print 'Create database...';
GO

-- create database
CREATE DATABASE [$(dbname)]
  ON PRIMARY
  ( NAME    = N'$(dbname)_dat1',
    FILENAME= N'$(dir)$(dbname)_dat1.mdf', -- N'F:\data\$(dbname)_dat1.mdf'
    SIZE=1GB, MAXSIZE=UNLIMITED, FILEGROWTH=128MB )
  --,FILEGROUP SeeLobGroup
  --( NAME    = N'$(dbname)_lob1',
  --  FILENAME= N'$(dir)$(dbname)_lob1.ndf', -- N'F:\data\$(dbname)_lob1.ndf'
  --  SIZE=1GB, MAXSIZE=UNLIMITED, FILEGROWTH=1GB )
  LOG ON
  ( NAME    = N'$(dbname)_log',
    FILENAME= N'$(dir)$(dbname)_log.ldf', -- N'G:\log\$(dbname)_log.ldf'
    SIZE=1GB, MAXSIZE=UNLIMITED, FILEGROWTH=128MB )
  COLLATE SQL_Latin1_General_CP1_CI_AS;
GO
ALTER DATABASE [$(dbname)] SET RECOVERY FULL WITH NO_WAIT;
GO
ALTER DATABASE [$(dbname)] SET ALLOW_SNAPSHOT_ISOLATION ON;
GO
ALTER DATABASE [$(dbname)] SET  READ_COMMITTED_SNAPSHOT ON;
GO

-- create logins for owner user
CREATE LOGIN [$(dbname)] WITH PASSWORD=N'$(ownpass)', CHECK_EXPIRATION=OFF,
  DEFAULT_DATABASE=[$(dbname)], DEFAULT_LANGUAGE=us_english;

-- for troubleshooting
GRANT VIEW SERVER STATE to [$(dbname)];
GRANT VIEW ANY DEFINITION to [$(dbname)];

GO

USE [$(dbname)];

-- add owner user to role
CREATE USER [$(dbname)] FOR LOGIN [$(dbname)];
ALTER ROLE db_owner ADD MEMBER [$(dbname)];

GO
print 'Finished create-database.'
GO
-- end of script
