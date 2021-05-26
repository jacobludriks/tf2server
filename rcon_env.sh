#!/bin/bash
# The -v flag is for the Azure Key Vault name. Assign to variable $vault
while getopts v: flag
do
    case "${flag}" in
        v) vault=${OPTARG};;
    esac
done

# Retrieve access token using system managed identity
accesstoken=$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://vault.azure.net' -H Metadata:true | jq --raw-output .access_token)

# Access Azure Key Vault using access token
rconpassword=$(curl -s "https://${vault}.vault.azure.net/secrets/rconpassword?api-version=2016-10-01" -H "Authorization:Bearer $accesstoken" | jq --raw-output .value)

# Export to an environmental variable
export RCON_PWD=$rconpassword