#!/bin/bash -x
exec 1>installer.log 2>&1

mkdir -p /home/eduk8s/bin

echo "### Installing kpack logs CLI"
VERSION=0.3.1
curl -L https://github.com/pivotal/kpack/releases/download/v$VERSION/logs-v$VERSION-linux.tgz | tar zx && \
    chmod +x logs && \
    mv logs /home/eduk8s/bin/logs
echo "### Finished installing kpack logs CLI"

echo -e "\n### Installing argocd CLI"
VERSION=v2.0.4
#VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
curl -sSL -o /home/eduk8s/bin/argocd https://github.com/argoproj/argo-cd/releases/download/${VERSION}/argocd-linux-amd64
chmod +x /home/eduk8s/bin/argocd
echo "### Finished installing argocd CLI"

echo -e "\n### Installing httpie CLI"
virtualenv /home/eduk8s/bin/httpie
source /home/eduk8s/bin/httpie/bin/activate
pip install httpie
deactivate
# Make sure the following line is in the file workshop/profile
#alias http="/home/eduk8s/bin/httpie/bin/http"
echo "### Finished installing httpie CLI"
