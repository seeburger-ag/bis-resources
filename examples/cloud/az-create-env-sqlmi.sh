#!/bin/bash
# TEMPLATE - Set up demo BIS Landscape with Az SQL MI
# Copyright 2025 SEEBURGER AG, Germany.
set -Eeu -o pipefail -o noclobber

# one time setup of SSH key for VM (replace with own)
ssh_id="$HOME/.ssh/id_seebisdemo"
ssh_id_pub="$ssh_id.pub"
if [ ! -f "$ssh_id_pub" ]; then
  echo "== Creating NEW SSH Keypair"
  mkdir -p ~/.ssh || true; 
  ssh-keygen -q -C "Azure/BIS demo key" -N '' -f "$ssh_id" < /dev/null
  az config set core.display_region_identified=false 2>/dev/null
fi

# read out current login properties to be used as admin
subscription="$(az account show --query id -o tsv)" # get current or specify
managed_by=("--managed-by" "$(az ad signed-in-user show --query id -o tsv)")
admin_sid="$(az ad signed-in-user show --query id -o tsv)"
admin_name="$(az ad signed-in-user show --query userPrincipalName -o tsv)"
myip="$(curl -s ifconfig.me)"

# configurable parameters
location='westeurope' # location of all resources
tier="${tier:-test}" # allows to have multiple tiers in subscription
job="${job:-2}" # allows to have multiple jobs in tier

admin_prefix=("$myip/32") # network prefix public source of access (SSH, Portal)
admin_sqluser='seedba' # initial DBA account
admin_pass='<Secret_Password>' # Important to change, keep comples
vnet_name_only='seebis'
vnet_prefix='10.129.0.0/16'
bis_subnet_name='subnet-apps'
bis_subnet_prefix='10.129.128.0/24'
db_subnet_name='subnet-mi'
db_subnet_prefix='10.129.0.0/26'
db_name='seeasdb0'
vm_user='seeadmin'
tags=("--tags" "owner=email@example.com" "stage=$tier" "com.seeburger.product=bis" )

# If not empty, prefix with '-'
tier="${tier:+-$tier}" 
job="${job:+-$job}"   # If not empty, prefix with '-'

# default RG name pattern
rg_name="rg-${vnet_name_only}$tier$job" # rg-seebis-prod-2

# Allows to use shared RG/subscription for private DNS zone
infra_rg_name="$rg_name" # "infra" or "${rg_name}-infra" 
infra_subscription="$subscription"

# Allows to use different RG for DB or app resources
bis_rg_name="$rg_name" # example: "rg-${vnet_name_only}-apps$tier$job"
db_rg_name="$rg_name"  # example: "rg-${vnet_name_only}-mi$tier$job"

# Does not need to have tier and job but helps with ad hoc admins
vm_install_name="bis-install$tier$job"

# derived with type prefix
vnet_name="vnet-${vnet_name_only}"
db_nsg="nsg-${vnet_name_only}-mi" # align with db_subnet_name
db_rt="rt-${vnet_name_only}-mi" # align with db_subnet_name
apps_nsg="nsg-${vnet_name_only}-apps" # align with bis_subnet_name
sqlmi_server_name="mi-${vnet_name_only}$tier$job" # mi-seebis-test-2

#az="echo az" for dry-run
az=$(which az)

echo "** Creating $rg_name in $location / sub=$subscription / myip=$myip"

echo "== Resource Group $bis_rg_name"
$az group create -o table \
  -n "$bis_rg_name" \
  --location "$location" \
  --subscription "$subscription" \
  "${managed_by[@]}" "${tags[@]}"

if [ x"$rg_name" != x"$db_rg_name" ]; then
  echo "=== Resource Group $db_rg_name"
  $az group create -o table \
    -n "$db_rg_name" \
    --location "$location" \
	--subscription "$subscription" \
    "${managed_by[@]}" "${tags[@]}"
fi

if [ x"$rg_name" != x"$infra_rg_name" ]; then
  echo "=== Resource Group $infra_rg_name"
  $az group create -o table \
    -n "$infra_rg_name" \
    --location "$location" \
	--subscription "$infra_subscription" \
    "${managed_by[@]}" "${tags[@]}"
fi

echo "== VNet $vnet_name"
$az network vnet create -o table \
  -n "$vnet_name" -g "$bis_rg_name" \
  --location "$location" \
  --address-prefix "$vnet_prefix"
  # flaky "${tags[@]}"


# Prepare components of MI subnet

if ! $az network nsg show -n "$db_nsg" -g "$db_rg_name" > /dev/null 2>&1; then
  echo "=== NSG for DB Subnet"
  # create this empty/early since delegation modifies it
  $az network nsg create -o table \
    -n "$db_nsg" -g "$db_rg_name"
fi

if ! az network route-table show -n "$db_rt" -g "$db_rg_name" > /dev/null 2>&1; then
  echo "=== RT for DB Subnet"
  # create this empty/early since delegation modifies it
  $az network route-table create -o table \
    -n "$db_rt" -g "$db_rg_name"
    # flaky "${tags[@]}"
fi

$az network route-table route create -o table \
  --name "to-${bis_subnet_name}" \
  --resource-group "$db_rg_name" \
  --route-table-name "$db_rt" \
  --address-prefix "$bis_subnet_prefix" \
  --next-hop-type VnetLocal


db_zone='privatelink.database.windows.net'
if ! az network private-dns zone show --name "$db_zone" -g "$infra_rg_name" > /dev/null 2>&1; then
  echo "=== DNS Zone $db_zone"
  $az network private-dns zone create -o table \
    -n "$db_zone" -g "$infra_rg_name" \
    --subscription "$infra_subscription"
fi

if ! az network private-dns link vnet show -n "dnslink-$vnet_name_only" -z "$db_zone" -g "$infra_rg_name" > /dev/null 2>&1; then 
  echo "=== DNS Zone Link $db_zone"
  $az network private-dns link vnet create -o table \
    -n "dnslink-$vnet_name_only" -g "$infra_rg_name" \
    --zone-name "$db_zone" \
    --virtual-network "/subscriptions/$subscription/resourceGroups/$bis_rg_name/providers/Microsoft.Network/virtualNetworks/$vnet_name" \
    --registration-enabled false
fi


echo "== DB Subnet"
# Unfortunatelly MI needs outbout access
$az network vnet subnet create -o table \
  -n "$db_subnet_name" -g "$db_rg_name" \
  --vnet-name "$vnet_name" \
  --default-outbound true \
  --address-prefix "$db_subnet_prefix" \
  --network-security-group "$db_nsg" \
  --route-table "/subscriptions/$subscription/resourceGroups/$bis_rg_name/providers/Microsoft.Network/routeTables/${db_rt}" \
  --delegation "Microsoft.Sql/managedInstances" 

echo "== NSG db rules"
$az network nsg rule create -o table \
  --nsg-name "$db_nsg" --resource-group "$db_rg_name" \
  --name AllowMSSQLIn \
  --priority 200 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes "$bis_subnet_prefix" \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 1433 11000-11999

# might need to delete 65000 and 65001


echo "== SQLMI Instance"
# Resize (cpu capacity, edition, iops and storage) this apropriately
# Configuration of redundancy not suited for prod
$az sql mi create -o table \
  -n "$sqlmi_server_name" -g "$db_rg_name" \
  --subnet "$db_subnet_name" --vnet "$vnet_name" \
	--location "$location" \
	--admin-user "$admin_sqluser" -p "$admin_pass" \
	--external-admin-principal-type "user" \
	--external-admin-name "$admin_name" \
	--external-admin-sid "$admin_sid" \
  --public-data-endpoint-enabled false \
  --timezone-id UTC \
  --collation SQL_Latin1_General_CP1_CI_AS \
  --database-format SQLServer2022 \
  --zone-redundant false \
  --backup-storage-redundancy Local \
  --license-type LicenseIncluded \
  -c 4 -e GeneralPurpose --gpv2 \
  --storage 32GB \
  "${tags[@]}"

# small  -c 4 -e GeneralPurpose --gpv2 --iops 1000 --storage 96GB
# medium -c 8 -e BusinessCritical --storage 320GB

echo "== SQLMI Database"
$az sql midb create -o table \
  -n "$db_name" -g "$db_rg_name" \
  --managed-instance "$sqlmi_server_name" \
  "${tags[@]}"


echo "== NSG apps"
# The following rules contain DB access
# Needs rules for intra-instance and ingress.
$az network nsg create -o table \
  -n "$apps_nsg" -g "$bis_rg_name"
  
$az network nsg rule create -o table \
  --nsg-name "$apps_nsg" --resource-group "$bis_rg_name" \
  --name AllowMSSQLOut \
  --priority 200 \
  --direction Outbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes "$db_subnet_prefix" \
  --destination-port-ranges 1433 11000-11999

# YUM update addresses should use local proxy
# probably needs more dest prefix entries
$az network nsg rule create -o table \
  --nsg-name "$apps_nsg" --resource-group "$bis_rg_name" \
  --name AllowUpdateOracleOut \
  --priority 3010 \
  --direction Outbound \
  --access Allow \
  --protocol 'Tcp' \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '23.0.0.0/8' '104.64.0.0/12' '184.50.0.0/16' \
  --destination-port-ranges 443 \
  --description 'yum.oracle.com via Akamai'

$az network nsg rule create -o table \
  --nsg-name "$apps_nsg" --resource-group "$bis_rg_name" \
  --name AllowUpdateMicrosoftOut \
  --priority 3011 \
  --direction Outbound \
  --access Allow\
  --protocol 'Tcp' \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '13.0.0.0/8' '20.0.0.0/8' \
  --destination-port-ranges 443 \
  --description 'packages.microsoft.com via Az FD'

# Allow direct access of admins (from Internet).
# This is unsafe for production use.
# port 22: system SSH to machine
# port 8443: default https portal for Installation Server and Admin Server Web UI.
$az network nsg rule create -o table \
  --nsg-name "$apps_nsg" --resource-group "$bis_rg_name" \
  --name AllowAdminIn \
  --priority 3100 \
  --direction Inbound \
  --access Allow\
  --protocol 'Tcp' \
  --source-address-prefixes "${admin_prefix[@]}" \
  --source-port-ranges '*' \
  --destination-address-prefixes "$bis_subnet_prefix" \
  --destination-port-ranges 22 8443 \
  --description '/!\ Admin Access from outside - not for prod'

 $az network nsg rule create -o table \
  --nsg-name "$apps_nsg" --resource-group "$bis_rg_name" \
  --name AllowBISUpdateOut \
  --priority 3200 \
  --direction Outbound \
  --access Allow\
  --protocol 'Tcp' \
  --source-address-prefixes "$bis_subnet_prefix" \
  --source-port-ranges '*' \
  --destination-address-prefixes '193.164.154.139/32' \
  --destination-port-ranges 443 \
  --description 'Access eu.service.seeburger.de'

$az network nsg rule create -o table \
  --nsg-name "$apps_nsg" --resource-group "$bis_rg_name" \
  --name DenyAllOut \
  --priority 4010 \
  --direction Outbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges '*'

$az network nsg rule create -o table \
  --nsg-name "$apps_nsg" --resource-group "$bis_rg_name" \
  --name DenyAllIn \
  --priority 4011 \
  --direction Inbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges '*'

# might need to delete 65000 and 65001

echo "== BIS subnet: $bis_subnet_name"
$az network vnet subnet create -o table \
  -n "$bis_subnet_name" -g "$bis_rg_name" \
  --vnet-name "$vnet_name" \
  --address-prefix "$bis_subnet_prefix"

echo "== NSG attach to $bis_subnet_name"
az network vnet subnet update -o table \
  --name "$bis_subnet_name" \
  --resource-group "$bis_rg_name" \
  --vnet-name "$vnet_name" \
  --network-security-group "$apps_nsg"


echo "== Installation Server VM"
# This can be used for testing, too small for BIS install
$az vm create -o table \
  --resource-group "$bis_rg_name" \
  --name "$vm_install_name" \
  --image Oracle:Oracle-Linux:ol95-lvm-gen2:9.5.2 \
  --size "Standard_DS1_v2" \
  -l "$location" \
  --admin-username "$vm_user" \
  --ssh-key-value "$ssh_id_pub" \
  --vnet-name "$vnet_name" \
  --subnet "$bis_subnet_name" \
  --nsg "$apps_nsg" \
  --nsg-rule None \
  "${tags[@]}"
