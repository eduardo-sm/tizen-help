#!/usr/bin/env bash

# Get version from package.json
newVersion=$(sed -nr "s/.*version.*\"([0-9]+\.[0-9]+\.[0-9]+)\".*/\1/p" package.json)

# Update version in tizen-help script
sed -r -i'.bak' -e "s/version=\"[0-9]+\.[0-9]+\.[0-9]+\"/version=\"$newVersion\"/g" tizen-help

# Remove temporal file created by sed
if [ -f tizen-help.bak ]; then
  rm tizen-help.bak
fi

git add tizen-help
