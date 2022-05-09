#!/bin/bash -x
exec 1>installer.log 2>&1

mkdir -p /home/eduk8s/bin

echo "### Installing kpack logs CLI"
VERSION=0.3.1
curl -L https://github.com/pivotal/kpack/releases/download/v$VERSION/logs-v$VERSION-linux.tgz | tar zx && \
    chmod +x logs && \
    mv logs /home/eduk8s/bin/logs
echo "### Finished installing kpack logs CLI"

echo -e "\n### Installing httpie CLI"
virtualenv /home/eduk8s/bin/httpie
source /home/eduk8s/bin/httpie/bin/activate
pip install httpie
deactivate
# Make sure the following line is in the file workshop/profile
#alias http="/home/eduk8s/bin/httpie/bin/http"
echo "### Finished installing httpie CLI"
