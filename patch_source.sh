#!/bin/bash

set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
GRAFANA_VERSION=6.7.1

cd $DIR

echo "+ Downloading tools"
export GOBIN=$DIR/bin
export PATH=$GOBIN:$PATH
go get github.com/go-bindata/go-bindata/go-bindata

echo "+ Creating grafana source cache directory"
mkdir -p .source_cache

echo "+ Downloading grafana source (v${GRAFANA_VERSION})"
if [[ -f ".source_cache/v${GRAFANA_VERSION}.zip" ]]; then
  echo "  - Previously downloaded, skip"
else
  curl -L https://github.com/grafana/grafana/archive/v${GRAFANA_VERSION}.zip --fail --output .source_cache/download_cache.zip
  mv .source_cache/download_cache.zip .source_cache/v${GRAFANA_VERSION}.zip
  echo "  - Downloaded to .source_cache/v${GRAFANA_VERSION}.zip"
fi

echo "+ Cleaning up stale source code"
rm -rf extracted

echo "+ Extracting source code"
mkdir extracted
unzip -q .source_cache/v${GRAFANA_VERSION}.zip -d extracted

echo "+ Building Grafana frontend"
cd extracted/grafana-${GRAFANA_VERSION}
make deps
make build-js

echo "+ Bundling into source file"
mkdir pkg/assets
go-bindata -o pkg/assets/bindata.go -pkg assets -fs public/...

echo "+ Applying source file patch"
patch -p1 < ${DIR}/grafana.diff

echo "+ Downloading backend dependendies"
go mod vendor

echo "+ Building standalone Grafana binary"
make build-server

echo "+ Done!"
echo "  - Please checkout directory: ${DIR}/extracted/grafana-${GRAFANA_VERSION}/bin"
