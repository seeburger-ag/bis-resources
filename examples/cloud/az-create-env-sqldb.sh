#!/bin/bash
# TEMPLATE - Set up demo BIS Landscape with Az SQL Database
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
admin_sid="$(az ad signed-in-user show --query id -o tsv)"
admin_name="$(az ad signed-in-user show --query userPrincipalName -o tsv)"
myip="$(curl -s ifconfig.me)"

# configurable parameters
location='westeurope' # location of all resources
tier='-test' # allows to have multiple tiers in subscription. Can be empty
job='-1' # makes it globally unique (besides private dns zone). Can be empty.
rg_name="rg-seebis$tier$job" # rg-seebis-prod-1 
admin_prefix=("$myip/32") # network prefix public source of access (SSH, Portal)
admin_pass='<Secret_Password>' # Important to change, keep comples

vnet_name='vnet-seebis'
vnet_prefix='10.129.0.0/16'
bis_subnet_name='subnet-apps'
bis_subnet_prefix='10.129.128.0/24'
db_subnet_name='subnet-db'
db_subnet_prefix='10.129.0.0/26'
db_name='seeasdb0'
tags=("--tags" "owner=email@example.com" "stage=$tier" "com.seeburger.product=bis" )
managed_by=("--managed-by" "$admin_sid")

# Allows to use shared RG/Subscription for private DNS zone
infra_rg_name="$rg_name" # "infra" or "${rg_name}-infra" 
infra_subscription="$subscription"

# Allows to use different RG for DB or app resources
bis_rg_name="$rg_name"
db_rg_name="$rg_name"

# Does not need to have tier and job but helps with ad hoc admins
vm_install_name="bis-install$tier$job"

sqldb_name="$db_name"
sqldb_server_name="seebisdb$tier$job"
sqldb_pe_name="pe-${sqldb_server_name}"

#az="echo az" for dry-run
az=$(which az)

echo "Creating $rg_name in $location / sub=$subscription / myip=$myip"

echo "== Resource Group $bis_rg_name"
$az group create -o table \
  -n "$bis_rg_name" \
  --location "$location" \
  --subscription "$subscription" \
  "${managed_by[@]}" "${tags[@]}"

if [ x"$rg_name" != x"$db_rg_name" ]; then
  echo "== Resource Group $db_rg_name"
  $az group create -o table \
    -n "$db_rg_name" \
    --location "$location" \
	--subscription "$subscription" \
    "${managed_by[@]}" "${tags[@]}"
fi

if [ x"$rg_name" != x"$infra_rg_name" ]; then
  echo "== Resource Group $infra_rg_name"
  $az group create -o table \
    -n "$infra_rg_name" \
    --location "$location" \
	--subscription "$infra_subscription" \
    "${managed_by[@]}" "${tags[@]}"
fi

echo "== VNet $vnet_name"
$az network vnet create -o table \
  -n "$vnet_name" -g "$bis_rg_name" \
  -l "$location" \
  --address-prefix "$vnet_prefix"
  # flaky "${tags[@]}"

echo "== BIS subnet"
$az network vnet subnet create -o table \
  -n "$bis_subnet_name" -g "$bis_rg_name" \
  --vnet-name "$vnet_name" \
  --address-prefix "$bis_subnet_prefix"

echo "== DB Subnet"
$az network vnet subnet create -o table \
  -n "$db_subnet_name" -g "$db_rg_name" \
  --vnet-name "$vnet_name" \
  --default-outbound false \
  --address-prefix "$db_subnet_prefix"


if ! az network private-dns zone show --name "privatelink.database.windows.net" -g "$infra_rg_name" > /dev/null 2>&1; then
  echo "DNS Zone"
  $az network private-dns zone create -o table \
    -n "privatelink.database.windows.net" -g "$infra_rg_name" \
    --subscription "$infra_subscription"
fi

if ! az network private-dns link vnet show -n "dnslink-$vnet_name" -z "privatelink.database.windows.net" -g "$infra_rg_name" > /dev/null 2>&1; then 
  echo "DNS Zone Link"
  $az network private-dns link vnet create -o table \
    -n "dnslink-$vnet_name" -g "$infra_rg_name" \
    --zone-name "privatelink.database.windows.net" \
    --virtual-network "/subscriptions/$subscription/resourceGroups/$bis_rg_name/providers/Microsoft.Network/virtualNetworks/$vnet_name" \
    --registration-enabled false
fi

echo "== NSG rules"
db_nsg="nsg-${vnet_name}-db"
$az network nsg create -o table \
  --resource-group "$db_rg_name" \
  --name "${db_nsg}"

$az network nsg rule create -o table \
  --nsg-name "${db_nsg}" --resource-group "$db_rg_name" \
  --name AllowMSSQLIn \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes "$bis_subnet_prefix" \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 1433 11000-11999

$az network nsg rule create -o table \
  --nsg-name "${db_nsg}" --resource-group "$db_rg_name" \
  --name DenyAllIn \
  --priority 4000 \
  --direction Inbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges '*'

$az network nsg rule create -o table \
  --nsg-name "${db_nsg}" --resource-group "$db_rg_name" \
  --name DenyAllOut \
  --priority 4010 \
  --direction Outbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges '*'

echo "== NSG attach to subnet-db"
az network vnet subnet update -o table \
  --name "$db_subnet_name" \
  --resource-group "$db_rg_name" \
  --vnet-name "$vnet_name" \
  --network-security-group "${db_nsg}"

# The following rules contain DB access
# Needs rules for intra-instance and ingress.
apps_nsg="nsg-${vnet_name}-apps"
$az network nsg create -o table \
  --resource-group "$bis_rg_name" \
  --name "${apps_nsg}"

$az network nsg rule create -o table \
  --nsg-name "${apps_nsg}" --resource-group "$bis_rg_name" \
  --name AllowMSSQLOut \
  --priority 100 \
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
  --nsg-name "${apps_nsg}" --resource-group "$bis_rg_name" \
  --name AllowUpdateOracleOut \
  --priority 3010 \
  --direction Outbound \
  --access Allow \
  --protocol 'Tcp' \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '23.0.0.0/8' '104.81.0.0/16' '184.50.0.0/16' \
  --destination-port-ranges 443 \
  --description 'yum.oracle.com via Akamai'
$az network nsg rule create -o table \
  --nsg-name "${apps_nsg}" --resource-group "$bis_rg_name" \
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
  --nsg-name "${apps_nsg}" --resource-group "$bis_rg_name" \
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
  --nsg-name "${apps_nsg}" --resource-group "$bis_rg_name" \
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
  --nsg-name "${apps_nsg}" --resource-group "$bis_rg_name" \
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
  --nsg-name "${apps_nsg}" --resource-group "$bis_rg_name" \
  --name DenyAllIn \
  --priority 4011 \
  --direction Inbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges '*'

echo "== NSG attach to subnet-apps"
az network vnet subnet update -o table \
  --name "$bis_subnet_name" \
  --resource-group "$bis_rg_name" \
  --vnet-name "$vnet_name" \
  --network-security-group "${apps_nsg}"


echo "== SQLDB Server"
$az sql server create -o table \
    -n "$sqldb_server_name" -g "$db_rg_name" \
	--location "$location" \
	--admin-user "seedba" -p "$admin_pass" \
	--external-admin-principal-type "user" \
	--external-admin-name "$admin_name" \
	--external-admin-sid "$admin_sid" \
	--enable-public-network false \
	--restrict-outbound-network-access true

echo "== SQLDB Database"
$az sql db create -o table \
  -n "$sqldb_name" -g "$db_rg_name" \
  -s "$sqldb_server_name" \
  -e Basic --service-objective Basic \
  --bsr Local -z false \
  --license-type LicenseIncluded \
  --max-size 2GB \
  --read-scale Disabled \
  "${tags[@]}"

# Small: -e GeneralPurpose -c 2 -f Gen5 \
# Medium: -e BusinessCritical -c 8 -f Gen5

echo "== SQLDB PE"
$az network private-endpoint create -o table \
  -n "$sqldb_pe_name" --resource-group "$db_rg_name" \
  --vnet-name "$vnet_name" --subnet "$db_subnet_name" \
  --private-connection-resource-id "/subscriptions/$subscription/resourceGroups/$db_rg_name/providers/Microsoft.Sql/servers/$sqldb_server_name" \
  --group-id "sqlServer" \
  --connection-name "${sqldb_pe_name}-conn" \
  -l "$location"
  # flaky "${tags[@]}"

echo "DNS Zone Group"
$az network private-endpoint dns-zone-group create -o table \
  --name "${sqldb_pe_name}-group" \
  --resource-group "$db_rg_name" \
  --endpoint-name "$sqldb_pe_name" \
  --private-dns-zone "/subscriptions/$infra_subscription/resourceGroups/$infra_rg_name/providers/Microsoft.Network/privateDnsZones/privatelink.database.windows.net" \
  --zone-name "privatelink.database.windows.net"


echo "== Installation Server VM"
# This can be used for testing, too small for BIS install
$az vm create -o table \
  --resource-group "$bis_rg_name" \
  --name "$vm_install_name" \
  --image Oracle:Oracle-Linux:ol95-lvm-gen2:9.5.2 \
  --size "Standard_DS1_v2" \
  -l "$location" \
  --admin-username "seeadmin" \
  --ssh-key-value "$ssh_id_pub" \
  --vnet-name "$vnet_name" \
  --subnet "$bis_subnet_name" \
  --nsg "${apps_nsg}" \
  --nsg-rule None \
  "${tags[@]}"
