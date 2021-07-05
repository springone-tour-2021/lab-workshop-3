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
source set-credentials.sh
```

### GitHub repositories

The following action blocks will fork the workshop repos into your own GitHub org.
> Note: These commands use the GitHub CLI (`hub`), which uses the GITHUB_USERNAME and GITHUB_TOKEN env vars set above, so it will be able to access your GitHub account.

> TODO: Update to us [gh](https://github.com/cli/cli) instead of hub ????
> TODO: Figure out how to use gh help secret set

> TODO: change to `git clone -b 1.0`

The following script will:
- Fork the app repo, `cat-service`
- Fork the `cat-service-release` repo, which will contain a copy of `cat-release`, once `cat-release` has passed all testing.
- Fork `cat-service-release-ops`, which contains the files for automating the deployment workflow.
```shell
source fork-repos.sh
```

At this point, you should see three new repositories in your GitHub org.
- `cat-service` contains the application code
- `cat-service-release` contains a copy the application code, tested and ready for deployment to prod
- `cat-service-release-ops` contains the Kubernetes deployment manifests, as well as files to set up the automated deployment workflow

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
