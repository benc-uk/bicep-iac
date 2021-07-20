#!/bin/bash
      echo "Waiting for control plane API to be available..."
      # Waits up to 5 mins for control plane to be ready on port 6443
      host=$1
      port=6443
      maxTries=60
      tries=0
      while ! nc -z $host $port; do  
        echo "POLL: $host:$port not open, waiting 5 seconds to try again..."
        sleep 5
        tries=$(( tries + 1 ))
        if (( $tries >= $maxTries )); then
          echo "FAILURE: Unable to connect to the $host:$port after $maxTries tries"
          exit 1
        fi
      done
      echo "SUCCESS: $host:$port is open and accepting connections"