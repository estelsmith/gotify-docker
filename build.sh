#!/bin/sh

set -e

cd /

echo Building with $(go --version)
echo Building with node $(node --version)
echo Building with yarn $(yarn --version)

git clone --branch "v${GOTIFY_VERSION}" --single-branch --depth 1 https://github.com/gotify/server.git build

cd build
make download-tools
go get -d

cd ui
yarn install
cd ..

go run hack/packr/packr.go

export BUILDDATE=$(date "+%F-%T")
export COMMIT=$(git rev-parse --verify HEAD)
export LD_FLAGS="-w -s -X main.Version=${GOTIFY_VERSION} -X main.BuildDate=${BUILDDATE} -X main.Commit=${COMMIT} -X main.Mode=prod";

go build -ldflags="${LD_FLAGS}" -o gotify-server
