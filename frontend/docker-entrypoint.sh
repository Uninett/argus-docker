#!/bin/sh -x
echo "STARTING STUFF!"
export HTTPS=false
export PORT=8080
npm run node server.js
echo "SHADDUP with code $?"
