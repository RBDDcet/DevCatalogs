#!/bin/bash
subscriptionId="572b41e6-5c44-486a-84d2-01d6202774ac"
az login --identity
az account set --subscription $subscriptionId
token=$(az account get-access-token --query "accessToken" -otsv)
BODY='{"location":"eastus"}'
echo $token
echo $(dpkg -l)
curl -X PUT -H "Authorization: Bearer $token" -H "Content-Type: application/json" -d "$BODY" https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/CharlieCharlie?api-version=2020-01-01