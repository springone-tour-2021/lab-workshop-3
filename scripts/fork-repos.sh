#!/usr/bin/bash

repos=('cat-service' 'cat-service-release' 'cat-service-release-ops')

# Check to see if repositories exist in the GitHub org specified as ${GITHUB_ORG}
echo -e "\nCheck to see if repos exist"
error_flag=0

for repo in "${repos[@]}"
do
  git ls-remote https://$GITHUB_TOKEN:x-oauth-basic@github.com/${GITHUB_ORG}/${repo} &>/dev/null
  error_code=$?
  if [[ $error_code == 0 ]]; then
    error_flag=1
    echo "ERROR: Repository https://github.com/${GITHUB_ORG}/${repo} already exists."
  fi
done

if [[ $error_flag == 1 ]]; then
  echo -e "\n!!!!! ERROR !!!!!\n"
  echo "Please delete the existing repositories and re-run this script."
  echo "You can delete the repos from https://github.com/${GITHUB_ORG}, or by typing:"
  echo "  hub delete ${GITHUB_ORG}/<repo-name> (requires delete_repo rights)"
  return
fi

# Check to see if local directories for the repos exist
echo -e "\nCheck to see if local directories exist"
error_flag=0
for repo in "${repos[@]}"
do
  if [ -d "${repo}" ] ; then
    error_flag=1
    echo "ERROR: Directory ${repo} already exists."
  fi
done

if [[ $error_flag == 1 ]]; then
  echo -e "\n!!!!! ERROR !!!!!\n"
  echo "Please delete the existing directories and re-run this script."
  echo "You can delete the directories by typing:"
  echo "  rm -rf <dir-name>"
  return
fi

# Clone and fork the three repos.
# Make changes to the references to GitHub and Docker registry
# Push changes to GitHub

echo -e "\nClone, fork and modify repo: cat-service"
hub clone https://github.com/booternetes-III-springonetour-july-2021/cat-service && cd cat-service
hub fork --remote-name origin
git branch --set-upstream-to origin/main
sed -i "s/booternetes-III-springonetour-july-2021/${GITHUB_ORG}/g" .github/workflows/deploy.sh
sed -i "s/mvn clean deploy/mvn clean package/g" .github/workflows/deploy.sh
git add .github/workflows/deploy.sh
git commit -m "Update GitHub org. Use mvn package instead of deploy."
git push --set-upstream origin main
cd ..

echo -e "\nClone, fork and modify repo: cat-service-release"
hub clone https://github.com/booternetes-III-springonetour-july-2021/cat-service-release && cd cat-service-release
hub fork --remote-name origin
git branch --set-upstream-to origin/release
cd ..
rm -rf cat-service-release

echo -e "\nClone, fork and modify repo: cat-service-release-ops"
hub clone https://github.com/booternetes-III-springonetour-july-2021/cat-service-release-ops && cd cat-service-release-ops
hub fork --remote-name origin
git branch --set-upstream-to origin/main
rm *.sh
rm manifests/overlays/dev/.argocd-source-dev-cat-service.yaml
rm manifests/overlays/prod/.argocd-source-prod-cat-service.yaml
find . -name *.yaml -exec sed -i "s/booternetes-III-springonetour-july-2021/${GITHUB_ORG}/g" {} +
find . -name *.yaml -exec sed -i "s/gcr\.io\/pgtm-jlong/${REGISTRY_HOST}/g" {} +
git add -A
git commit -m "Update GitHub org and Docker registry. Remove unnecessary files."
git push --set-upstream origin main
cd ..
