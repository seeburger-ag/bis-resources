Sample resources for *SEEBURGER BIS* on public clouds.

## Files

* `az-create-env-sqldb.sh` - Bash script to generate a sample environment on Azure (using **Azure SQL Database** as system database).
* `az-create-env-sqlmi.sh` - Bash script to generate a sample environment on Azure (using **Azure SQL Managed Instance** as system database).


## Create Demo Environment (SQL Database) `az-create-env-sqldb.sh`

The script *`az-create-env-sqldb.sh`* is used to set up a BIS Landscape on _Azure_, using _SQL Database_ as the system database.
It will create the _Resource Group(s)_, _Virtual Network_, _Subnets_, _Network Security Groups_, _(logical) Database Server_, _SQL Database_ and a single _VM_ for further installation of the _SEEBURGER Installation Server_.

### Script Configuration

This script is not production ready, for example it does not use a local update repository proxy, uses initial passwords, and it allows SSH access directly to the generated VM.

The capacity for the database and the size for the VM is NOT suitable to actually run a BIS installation.
The script uses the smallest variants for cost reduction.

You can pick one of two modes: either everything installed in a single resource group (`infra_rg_name="$rg_name"`) or with a shared infrastructure (`infra_rg_name=any_other_value`) resource group specifically for the _private DNS Zone_ `privatelink.database.windows.net`.

The database is reachable via a private endpoint, which is deployed in a dedicated database subnet.

By default the following is created:

* `$tier` - Allows to have one resource group by tier (default: `'test'`)
* `$job` - optional suffix to make rg name unique (default:`'1'` or `'2'`)
* `$location` - the region you want to create all of the resources (default: ``westeurope``)
* `$tags` - allow to tag some resources with meta-data.
Some resources cannot be tagged with the CLI.
* `$rg_name` - the name of the main resource group, includes tier and job (default: `'rg-seebis-$tier-$job'`)
* `$infra_rg_name` - alternative name for shared RG for DNS Zone (default: `$rg_name`)
* `$sqldb_server_name` - The server used in URL (default: `'db-seebis-test-1'`)
* `$db_name` - The managed database name (default: `'SEEASDB0'`)
* `$admin_prefix` - The network prefixes array to allow administrative access to SSH and portals.
Should be limited to your internet address or not used at all in production.
(defaults to own ip/32)
* `$admin_pass` - The initial dba password (SQL Authentication).
Important to fill with new random one. (Unsecure default: `'<Secret_Password>'`)

Further relevant settings are `vm_user`, `admin_sqluser` for the OS and SQL admin users.
`vnet_name`, `vnet_prefix`, `bis_subnet_name`, `bis_subnet_prefix`, `db_subnet_name`, and `db_subnet_prefix` for the network names and IP ranges.

If the addresses of _Oracle Yum Repo_ or _Microsoft Packages_ download servers change, you might need to adjust the allowed prefixes in the NSG rules.
In production you should use a local mirror and you will need to allow services like the load balancers.


## Script execution

Before you can start one of the scripts, make sure you have `bash`, `curl`, `ssh-keygen` and _Azure CLI_ installed and you are logged into an Azure account (with "`az login`") with appropriate permissions on a non-productive Azure subscription.

Beware the costs of running resources.
The script can be executed inside _Azure CloudShell_ (Bash).
The script does not take parameters, all configuration must be done inside the variable assignments in the script.

After running the script, it will have created a local SSH key `~/.ssh/id_seebisdemo` to log into the VM via SSH to the listed public address.
This step is skipped if you provided a different public key in `~/.ssh/id_seebisdemo.pub` for it, already.
Please ensure to persist the generated key if your Cloud Shell is volatile.

The script can be run multiple times, minor changes may be applied.
However not all changes or structural changes are synced by this naive approach.
You might need to destroy the whole resource group to re-create it.

If you want to deploy multiple environments in your subscription, you can specify them with the `job`  (which overwrites `job=1` for DB and `job=2` for MI script) and/or `tier` (overwrites `test`) environment variables


````console
> job=4 tier="qa" ./az-create-env-sql*.sh
````

Replace `*` with `db` or `mi` to run the aproperiate script.
this will provision the resources into a resource group called `rg-seebis-qa-4`.
The VNet is by default called `vnet-seebis` in all cases.


## Create Demo Environment (SQL MI) `az-create-env-sqlmi.sh`

The script *`az-create-env-sqlmi.sh`* is used to set up a BIS Landscape on _Azure_, using _Azure SQL Managed Instance_ as the system database.
Execution takes at least half an hour (creation of MI step is slow).

The script has the same configuration and execution logic as the `az-create-env-sqldb.sh`, but instead of a private endpoint, it directly generates the Managed Instance of SQL Server in the database subnet called `subnet-mi`.

* `$sqlmi_server_name` - The SQL Managed Instance server name, used in URL (default: `mi-seebis-test-2`).
The final fully qualified name of the server contains a random component, you need to look it up from the console.


## Post creation steps

The VM is set up with the initial Linux user "`seeadmin`".


**Connecting the VM with SSH**

The public IP of the VM is printed as the last line of the script output, or can be queried with this command:

```console
> az vm list-ip-addresses -g rg-seebis-test-2
```

use this IP to connect with a SSH client specifying the matching private key:

```console
> ssh -i ~/.ssh/id_seebisdemo seeadmin@1.2.3.4
```

This only works from a machine with allow-listed IP-address.


**Connecting to the SQL Database**

The database is set up with the initial SQL authentication "`seedba`"/"`<Secret_Password>`" and the _Entra ID_ user as alternative admin.
Make sure to change the password in the script before applying it.

To get started on the VM, install the `sqlcmd` utility as described here by Microsoft:
https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools

* go-sqlcmd release page: https://github.com/microsoft/go-sqlcmd/releases/

The name of the database server uses the following patterns by defsult:

* SQL Database: `db-seebis-$tier-$job.database.windows.net` (`$sqldb_server_name`)
* SQL MI: `mi-seebis-$tier-$job.<random>.database.windows.net` (`$sqlmi_server_name`)

The fully qualified domain name of the SQL Managed Instance will include a random subdomain string to make it unique, use the "`az sql mi show -g rg-seebis-test-2 -n mi-seebis-test-2`" command to look it up.

Both names will alias to a unique name in the `privatelink.database.windows.net` private DNS zone.

Find the SQL script templates to create the database users in the [`installation/systemdatase/mssql`](../../installation/systemdatabase/mssql) directory of this repository.


**Installing the BIS Installation Server**

If you want to use the Internet exposed Web UI of the Installation Server (not reccomended), be sure to create a TLS certificate and enable the listener (port 8443).
Alternatively you can use ssh port forwarding (port 22 is open) for the 8181 http port.
By default only the public visible IP address of the host where the script was executed is allow listed in the NSG for SSH and portal administrative access.
If you need more admin machines, modify the `$admin_prefix` array.

We recommand to use SSH port forwarding for initial configuration of the Installation Server (http port 8181).


## Cleanup

After you finished your experiments, you can clean up (deletes everything!) with "`az group delete -n rg-seebis-x-x`".
This is required to stop additional usage costs.


## Troubleshooting

To validate connectivity with the Azure API and to list all existing resource groups, use `az group list -o table` for your default subscription.

To trace the commands of the creation script, start it with `job=5 bash -x az-create-env-sql*.sh | tee -a logfile.txt`.

From the VM command line you can use the `dig +short x-seebis-x-x.x.database.windows.net` command to list the name resolution results of the database private endpoint (replace actual name listed above)
It should eventuelly list a private IP from the DB subnet.

Use the `nc -v <servername> 1433` command to check basic connectivity, and the `sqlcmd -U seedba -S <servername> -X 1 -Q "select db_name()"` to validate the logins (will print "`master`" for `seedba` user and "`SEEASDB0`" for the owner and runtime users - after you have created them).

If you do not use SSH port forwarding to reach the installation server (`-L 8181:127.0.0.1:8181` parameter) you need to enable portal access to the running Installation Server.
For this, remember to open incoming port 8443 in the _firewalld_ configuration of the EL9 host.
You also need to create a new TLS certificate and enable the https listener on port 8443 in the Installation Server.

By default EL9 comes with _SELinux_ in enforcing mode, for quick testing we recommend to switch with the `sudo setenforce permissive` command.
You otherwise get resource permission errors when starting the systemd service of the _Installation Server_.
