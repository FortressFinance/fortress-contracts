#!/bin/bash
set -e

echo "Updating addresses....."

NEW_FORTRESS_REGISTRY=$(cat script/mainnet/utils/registry.txt)

echo "Updating addresses on Backend repo for mainnet"
echo "Fortress Registry: $NEW_FORTRESS_REGISTRY"

cd /
git clone https://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@github.com/FortressFinance/Backend
cd Backend
git pull
git fetch
git switch staging
git pull
OLD_FORTRESS_REGISTRY=$(cat util/addresses.json | jq -r '.FortressRegistry')
sed -i "s/$OLD_FORTRESS_REGISTRY/$NEW_FORTRESS_REGISTRY/g" util/addresses.json
git add .
git commit -m "Update fortress registry address"
git push origin staging

