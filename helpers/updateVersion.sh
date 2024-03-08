#!/usr/bin/env bash

# Get version from package.json
newVersion=$(sed -nr "s/.*version.*\"([0-9]+\.[0-9]+\.[0-9]+)\".*/\1/p" package.json)

# Update version in tizen-help script
sed -r -i'.bak' -e "s/version=\"[0-9]+\.[0-9]+\.[0-9]+\"/version=\"$newVersion\"/g" tizen-help
sed -r -i'.bak' -e "s/version=\"[0-9]+\.[0-9]+\.[0-9]+\"/version=\"$newVersion\"/g" tizen-help.ps1

# Remove temporal file created by sed
[ -f tizen-help.bak ] && rm tizen-help.bak
[ -f tizen-help.ps1.bak ] && rm tizen-help.ps1.bak

git add tizen-help
