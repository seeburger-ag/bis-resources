Oracle based system database for *SEEBURGER BIS6*.

## See Also

This directory contains the resources mentioned in the
**BIS6 System Database Manual** with templates
and samples to create a system database for a *SEEBURGER
BIS 6.7* installation.

Please see the manual for explanation, caveats and usage
description. Make sure to understand and adjust the statements
before executing them against your database.

## Files

The scripts are generally compatible with the `sqlplus` client.

* `create-tbs.sql` - as DBA create a number of application specific tablespaces.
* `create-roles.sql` - create sample roles SEECONNECT and SEERESOURCE as well as profile SEERUNTIME.
* `create-schema.sql` - create empty schema SEEASDB0 for application.
* `create-user.sql` - create sample runtime user SEERUN0 for application.
* `grant-runtime-user.sql` - optional assign schema permissions for runtime user.
