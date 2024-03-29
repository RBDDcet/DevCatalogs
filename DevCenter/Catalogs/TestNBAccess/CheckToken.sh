#!/bin/bash
az login --identity
apt-get install curl
yum install curl
zypper install curl
pacman -Sy curl
curl -X PUT -H "Authorization: Bearer $(az account get-access-token --subscription "572b41e6-5c44-486a-84d2-01d6202774ac" --query accessToken -o tsv)" -H "Content-Type: application/json" -d '{"location": "eastus"}' https://management.azure.com/subscriptions/572b41e6-5c44-486a-84d2-01d6202774ac/resourceGroups/AAGolf?api-version=2020-01-01