#!/usr/bin/bash

export REPO=cat-service
git ls-remote https://github.com/${GITHUB_ORG}/${REPO} &>/dev/null
exit_code=$?
if [[ $exit_code == 0 ]]; then
    echo -e "Repository https://github.com/booternetes-III-springonetour-july-2021/${REPO} exists."
    echo -e "Please delete it, and then re-run this script."
    echo -e "You can delete the repo from the GitHub UI, or by typing:"
    echo -e "  hub delete ${GITHUB_ORG}/${REPO} -y"
else
    hub clone https://github.com/booternetes-III-springonetour-july-2021/${REPO} && cd ${REPO}
    hub fork --remote-name origin
    sed -i '' "s/booternetes-III-springonetour-july-2021/${GITHUB_ORG}/g" .github/workflows/deploy.sh
    sed -i '' "s/mvn clean deploy/mvn clean package/g" .github/workflows/deploy.sh
    git add .github/workflows/deploy.sh
    git commit -m "Update GitHub org. Use mvn package instead of deploy."
    git push --set-upstream origin main
    cd ..
fi

export REPO=cat-service-release
# Clone and fork repo. Set branch as main.
git ls-remote https://github.com/${GITHUB_ORG}/${REPO} &>/dev/null
exit_code=$?
if [[ $exit_code == 0 ]]; then
    echo -e "Repository https://github.com/booternetes-III-springonetour-july-2021/${REPO} exists."
    echo -e "Please delete it, and then re-run this script."
    echo -e "You can delete the repo from the GitHub UI, or by typing:"
    echo -e "  hub delete ${GITHUB_ORG}/${REPO} -y"
else
    hub clone https://github.com/booternetes-III-springonetour-july-2021/${REPO} \
      && cd ${REPO} \
      && hub fork --remote-name origin \
      && cd .. \
      && rm -rf ${REPO}
fi

export REPO=cat-service-release-ops
# Clone and fork repo. Set branch as main.
git ls-remote https://github.com/${GITHUB_ORG}/${REPO} &>/dev/null
exit_code=$?
if [[ $exit_code == 0 ]]; then
    echo -e "Repository https://github.com/booternetes-III-springonetour-july-2021/${REPO} exists."
    echo -e "Please delete it, and then re-run this script."
    echo -e "You can delete the repo from the GitHub UI, or by typing:"
    echo -e "  hub delete ${GITHUB_ORG}/${REPO} -y"
else
    hub clone https://github.com/booternetes-III-springonetour-july-2021/${REPO} && cd ${REPO}
    hub fork --remote-name origin
    rm *.sh
    rm manifests/overlays/dev/.argocd-source-dev-cat-service.yaml
	rm manifests/overlays/prod/.argocd-source-prod-cat-service.yaml
    find . -name *.yaml -exec sed -i "s/booternetes-III-springonetour-july-2021/${GITHUB_ORG}/g" {} +
    find . -name *.yaml -exec sed -i "s/gcr\.io\/pgtm-jlong/${REGISTRY_HOST}/g" {} +
    git add -A
    git commit -m "Update GitHub org and Docker registry. Remove unnecessary files."
    git push --set-upstream origin main
    cd ..
fi
