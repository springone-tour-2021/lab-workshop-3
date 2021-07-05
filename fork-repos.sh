#!/usr/bin/bash

# Check to see if repos exist

repos=('cat-service' 'cat-service-release' 'cat-service-release-ops')
error_flag=0

for repo in "${repos[@]}"
do
  git ls-remote https://github.com/${GITHUB_ORG}/${repo} &>/dev/null
  error_code=$?
  if [[ $error_code == 0 ]]; then
    error_flag=1
    echo -e "ERROR: Repository https://github.com/${GITHUB_ORG}/${repo} already exists."
  fi
done

if [[ $error_flag == 1 ]]; then
  echo
  echo "!!!!! ERROR !!!!!"
  echo
  echo "Please delete the existing repositories and re-run this script."
  echo "You can delete the repos from the GitHub UI, or by typing:"
  echo "  hub delete ${GITHUB_ORG}/<repo-name>"
  return
fi

# Fork and modify repos

# cat-service
hub clone https://github.com/booternetes-III-springonetour-july-2021/cat-service && cd cat-service
hub fork --remote-name origin
sed -i '' "s/booternetes-III-springonetour-july-2021/${GITHUB_ORG}/g" .github/workflows/deploy.sh
sed -i '' "s/mvn clean deploy/mvn clean package/g" .github/workflows/deploy.sh
git add .github/workflows/deploy.sh
git commit -m "Update GitHub org. Use mvn package instead of deploy."
git push --set-upstream origin main
cd ..

#cat-service-release
hub clone https://github.com/booternetes-III-springonetour-july-2021/cat-service-release \
  && cd cat-service-release \
  && hub fork --remote-name origin \
  && cd .. \
  && rm -rf cat-service-release

# cat-service-release-ops
hub clone https://github.com/booternetes-III-springonetour-july-2021/cat-service-release-ops && cd cat-service-release-ops
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
