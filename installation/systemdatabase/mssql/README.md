*MS SQL Server* based system database for *SEEBURGER BIS6*.

## See Also

This directory contains the resources mentioned in the
**BIS6 System Database Manual** with templates
and samples to create a system database for a *SEEBURGER
BIS 6.7* installation.

Please see the manual for explanation, caveats and usage
description. Make sure to understand and adjust the statements
before executing them against your database.

## Files

The scripts are generally compatible with the `sqlcmd` client.

### Microsoft SQL Server

* `create-database.sql` - create a empty application database.
* `create-user.sql` - create sample database user for application.

### Microsoft Azure SQL Database

* `create-database-azure.sql` - create a empty application database for Azure SQL Database.
* `create-users-azure.sql` - create sample users for application for Azure SQL Database.
