#!/usr/bin/env bash

DGRAPH_CONTAINER_NAME=dlex-dgraph

if docker ps -a --format '{{.Names}}' | grep -Eq "^${DGRAPH_CONTAINER_NAME}\$"; then
  echo "Already running..."
else
  echo "Starting local dgraph server via Docker..."
  docker run --name $DGRAPH_CONTAINER_NAME -p 8080:8080 -p 9080:9080 -d dgraph/standalone:v1.1.1
fi
echo "Done."
