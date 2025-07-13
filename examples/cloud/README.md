Sample resources for *SEEBURGER BIS* on public clouds.

## Files

* `az-create-env-sqldb.sh` - Bash script to generate a sample environment on Azure (using Azure SQL Database as system database).


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

* `$tier` - Allows to have one resource group by tier (default `'-test'`)
* `$job` - optional suffic to make rg name unique (default `'-1'`)
* `$location` - the region you want to create all of the resources (default: ``westeurope``)
* `$tags` - allow to tag some resources with meta-data. (For some resources the `az` CLI does not work reliable, it is marked with "flaky" comment).
Some resources do not allow to be tagged.
* `$rg_name` - the name of the main resource group, includes tier and job (default: `'seebis-test-1'`)
* `$infra_rg_name` - alternative name for shared RG for DNS Zone (default: `$rg_name`)
* `$sqldb_server_name` - The server used in URL (default `'seebisdb-test-1'`)
* `$db_name` - The managed database name (default `'SEEASDB0'`)
* `$admin_prefix` - The network prefixes to allow administrative access to SSH and portals.
Should be limited to your internet address or not used at all in production.
(defaults to own ip/32)
* `$admin_pass` - The initial dba password (SQL Authentication).
Important to fill with new random one. (Unsecure default `'<Secret_Password>'`)

Further relevant settings are `vnet_name`, `vnet_prefix`, `bis_subnet_name`, `bis_subnet_prefix`, `db_subnet_name`, and `db_subnet_prefix` and `tags`.

If the addresses of _Oracle_ or _Microsoft_ download servers change, you might need to adjust the allowed prefixes in the NSG rules.
In production you should use a local mirror and you will need to allow services like the load balancers.


### Script execution

Before you can start the script, make sure you have `bash`, `curl`, `ssh-keygen` and _Azure CLI_ installed and you are logged into an Azure account (with "`az login`") with appropriate permissions on a non-productive Azure subscription.

Beware the costs of running resources.
The script can be executed inside _Azure CloudShell_ (Bash).
The script does not take parameters, all configuration must be done inside the variable assignments in the script.

After running the script, it will have created a local SSH key `~/.ssh/id_seebisdemo` to log into the VM via SSH to the listed public address.
This step is skipped if you provided a different public key in `~/.ssh/id_seebisdemo.pub` for it, already.

The script can be run multiple times, minor changes may be applied.
However not all changes or structural changes are synced by this naive approach.
You might need to destroy the whole resourc group to re-create it.


## Post creation steps

The VM is set up with the initial Linux user "*`seeadmin`*".

The public IP of the VM is printed as the last line of the script output.

**Connecting the VM with SSH**

```console
> ssh -i ~/.ssh/id_seebisdemo seeadmin@1.2.3.4
```

This only works from the initial IP-address you executed the script.


**Conneting to the SQL Database**

The database is set up with the initial SQL authentication "*`seedba`*"/"*`<Secret_Password>`*" and the Entra user as alternative admin.
Make sure to change the password in the script before using it.

To get started on the VM, install the `sqlcmd` utility as described here by Microsoft:
https://learn.microsoft.com/en-us/sql/linux/sql-server-linux-setup-tools?tabs=redhat-install#RHEL


**Installing the BIS Installation Server**

If you want to use the Internet accessible portal option for the Installation Server, be sure to create a TLS certificate and enable the listener (port 8443).
Alternatively you can use ssh port forwarding (port 22 is open) for the 8181 http port.
By default only the public visible IP address of the host where the script was executed is allow listed in the NSG for SSH and portal administrative access.
If you need more admin machines, modify `admin_prefix`.

We recommand to use ssh port forwarding for initial configuration of the Installation Server (http port 8181).


### Cleanup

After you finished your experiments, you can clean up (deletes everything!) with "`az group delete -n rg-seebis-test-1`".


### Troubleshooting

To see the progress of the script, start it with `bash -x az-create-env-sqldb.sh`, and to check if the `az` CLI can login, use `az group list -o table` to see the existing resource groups in your default subscription.

From the VM command line you can use the `dig +short seebisdb-test-1.database.windows.net` command to list the name resolution results or the database private endpoint.
It should eventuelly list a private IP from the DB subnet.

Use the `nc -v seebisdb-test-1.database.windows.net 1433` command to check basic connectivity and the `sqlcmd -U seedba -S seebisdb-test-1.database.windows.net -Q "select dbname();"` to validate the login.

If you do not use ssh port forwarding to reach the installation server (`-L 8181:127.0.0.1:8181` parameter) you need to enable portal access to the running Installation Server.
For this, remember to open incoming port 8443 in the _firewalld_ configuration of the EL9 host.
You also need to create a new TLS certificate and enable the https listener on port 8443 in the Installation Server.

By default EL9 comes with SELinux in enforcing mode, for quick testing we recommend to switch with the `sudo setenforce permissive` command.
You otherwise get resource permission errors when starting the systemd service of the _Installation Server_.
