#!/bin/bash -x
exec 1>installer.log 2>&1

echo -e "\n### Configuring git global settings"
git config --global hub.protocol https
git config --global credential.helper cache
git config --global user.email "guest@example.com"
git config --global user.name "Guest User"
echo "### Finished configuring git global settings"

mkdir -p /home/eduk8s/bin

echo -e "\n### Installing hub CLI"
HUB_VERSION=2.14.2
curl -L https://github.com/github/hub/releases/download/v${HUB_VERSION}/hub-linux-amd64-${HUB_VERSION}.tgz | tar zx && \
     mv hub-linux-amd64-2.14.2/bin/hub /home/eduk8s/bin/ && \
     rm -rf hub-linux-amd64-${HUB_VERSION}
echo "### Finished installing hub CLI"

echo -e "\n### Installing gh CLI"
GH_VERSION=1.12.1
curl -L https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz | tar zx && \
     mv gh_${GH_VERSION}_linux_amd64/bin/gh /home/eduk8s/bin/ && \
     rm -rf gh_${GH_VERSION}_linux_amd64
echo "### Finished installing gh CLI"

echo -e "\n### Installing argocd CLI"
#ARGOCD_VERSION=2.0.4
#https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-amd64
VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
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

clear
