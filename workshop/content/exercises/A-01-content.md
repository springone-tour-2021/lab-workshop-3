## Cats, Cats, Everywhere

Throughout this workshop, you will be using an application that returns cat names and ages.

The application comprises a Spring Boot app and a database:
- cat-service - Exposes an enpoint "/cats/{name}" and returns the cat's name and age in months.
- cat-postgres - Stores the names and birth dates of cats.

## Prerequisites

You will need a [GitHub account](https://github.com) and a [personal access token](https://helphub.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) (with "repo" access rights).

### Environment variables

Run the following commands and enter the appropriate values at the prompts.
```execute-1
echo -n "Enter your GitHub username [${GITHUB_USERNAME}]: " && read GITHUB_USERNAME
export GITHUB_USERNAME

echo -n "Enter your GitHub auth token: " && read -s GITHUB_TOKEN || { stty -echo; read GITHUB_TOKEN; stty echo; }
export GITHUB_TOKEN
echo

echo -n "Enter your GitHub org name [${GITHUB_USERNAME}]: " && read GITHUB_ORG
GITHUB_ORG="${GITHUB_ORG:-$GITHUB_USERNAME}"
export GITHUB_ORG
```

### GitHub repositories

The following action blocks will fork the workshop repos into your own GitHub org.
> Note: These commands use the GitHub CLI (`hub`), which uses the GITHUB_USERNAME and GITHUB_TOKEN env vars set above, so it will be able to access your GitHub account.

> TODO: Update to us [gh](https://github.com/cli/cli) instead of hub ????
> TODO: Figure out how to use gh help secret set

> TODO: change to `git clone -b 1.0`

First, fork the app repo, `cat-service`.
```shell
export REPO=cat-service
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
    sed -i '' "s/booternetes-III-springonetour-july-2021/${GITHUB_ORG}/g" .github/workflows/deploy.sh
    sed -i '' "s/mvn clean deploy/mvn clean package/g" .github/workflows/deploy.sh
    git add .github/workflows/deploy.sh
    git commit -m "Update GitHub org. Use mvn package instead of deploy."
    git push --set-upstream origin main
    cd ..
fi
```

Next, fork the `cat-service-release` repo, which will contain a copy of `cat-release`, once `cat-release` has passed all testing.
```shell
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
```

Finally, fork `cat-service-release-ops`, which contains the files for automating the deployment workflow.
```shell
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
```

At this point, you should see three new repositories in your org.
- `cat-service` contains the application code
- `cat-servicerelease` contains a copy the application code, tested and ready for deployment to prod
- `cat-service` contains the Kubernetes deployment manifests, as well as files to set up the automated deployment workflow

You do not need to understand the contents of these repos yet. 
You will go through them as you proceed through this workshop.

Before continuing, there is one additional change you need to make.
Open the `cat-service` repository.
```dashboard:open-url
url: https://github.com/${GITHUB_ORG}/cat-service
```

> TODO: Add instructions to guide user to adding the necessary env variables for the GitHub action. No need to include the artifactory ones.
> 
Open the repo in your browser.
```dashboard:open-url
url: https://github.com/${GITHUB_ORG}/cat-service
```

To enable GitHub Actions to push the tested `cat-service` code to `cat-service-release`:
- Navigate to Settings -> Secrets -> New repository secret.
- Create a secret called GIT_USERNAME with your GitHub username
- Create another secret called GIT_PASSWORD with your access token

---
---
---

Sandbox area:
```shell
gh secret set GIT_USERNAME -b"${GITHUB_USERNAME}" --org=${GITHUB_ORG} --repos ${GITHUB_ORG}/cat-service
gh secret set GIT_PASSWORD
```
