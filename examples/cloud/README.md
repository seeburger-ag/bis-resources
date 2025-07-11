Sample resources for *SEEBURGER BIS* on public clouds.

## Files

* `az-create-env-sqldb.sh` - Bash script to generate a sample environment on Azure (using Azure SQL Database as system database).

## Create Demo Environment (SQL Database) `az-create-env-sqldb.sh`

The script *`az-create-env-sqldb.sh`* is used to set up a BIS Landscape on _Azure_, using _SQL Database_ as the system database.
It will create the _Resource Group(s)_, _Virtual Network_, _logical Database Server_, _SQL Database_ and a single _VM_ for further installation.

This script is not production ready, for example it does not use a local update repository proxy, uses initial passwords, and it allows SSH access directly to the generated VM.

The capacity for the database and the size for the VM is NOT suitable to actually run a BIS installation.
The script uses the smallest variants for cost reduction.

You can pick one of two modes: either everything installed in a single resource group (`infra_rg_name="$rg_name"`) or with a shared infrastructure (`infra_rg_name=any_other_value`) resource group specifically for the _private DNS Zone_ `privatelink.database.windows.net`.

The database is reachable via a private endpoint, which is deployed in a dedicated database subnet.

By default the following is created:

* `$tier` - Allows to have one resource group by tier (default `'-test'`)
* `$job` - optional suffic to make rg name unique (default `'-1'`)
* `$location` - the region you want to create all of the resources (default: ``westeurope``)
* `$tags` - allow to tag some resources with meta-data. (For some resources the `az` CLI does not work reliable, it is marked with "flaky" comment).
Some resources do not allow to be tagged.
* `$rg_name` - the name of the main resource group, includes tier and job (default: `'seebis-test-1'`)
* `$infra_rg_name` - alternative name for shared RG for DNS Zone (default: `$rg_name`)
* `$sqldb_server_name` - The server used in URL (default `'seebisdb-test-1'`)
* `$db_name` - The managed database name (default `'SEEASDB0'`)

Further relevant settings are `vnet_name`, `vnet_prefix`, `bis_subnet_name`, `bis_subnet_prefix`, `db_subnet_name`, and `db_subnet_prefix`.
If the addresses of _Oracle_ or _Microsoft_ download servers change, you might need to adjust the allowed prefixes in the NSG rules.
In production you should use a local mirror.

Before you can start the script, make sure you have `bash`, `ssh-keygen` and _Azure CLI_ installed and you are logged into an Azure account (with "`az login`") with appropriate permissions on a non-productive Azure subscription.
Beware the costs of running resources.
The script can be executed inside _Azure CloudShell_ (Bash).
The script does not take parameters, all configuration must be done inside the variable assignments in the script.

After finishing the script, it will have created a local SSH key `~/.ssh/id_seebisdemo` to log into the VM via SSH to the listed public address.

The script can be run multiple times, minor changes may be applied.
However not all changes or structural changes are synced by this naive approach.
You might need to destroy the whole resourc group to re-create it.

The VM is set up with the initial Linux user "*`seeadmin`*".
The database is set up with the initial SQL authentication "*`seedba`*"/"*`<Secret_Password>`*" and the Entra user as alternative admin.
Make sure to change the password in the script before using it.

To get started on the VM, install the `sqlcmd` utility as described here by Microsoft:
https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools?tabs=redhat-install#RHEL

After you finished your experiments, you can clean up (deletes everything!) with "`az group delete -n rg-seebis-test1`".

