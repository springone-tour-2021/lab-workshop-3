## Cats, Cats, Everywhere

Throughout this workshop, you will be using an application that returns cat names and ages.

The application comprises a Spring Boot app and a database:
- **cat-service** - Exposes an enpoint "/cats/{name}" and returns the cat's name and age in months.
- **cat-postgres** - Stores the names and birth dates of cats.

## Prerequisites

You will need:
- A GitHub [account](https://github.com)
- A GitHub [personal access token](https://helphub.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line) (with "repo" and "workflow" access rights)
  
Make sure you have those ready before proceeding.

### Environment variables

Run the following command and enter the appropriate values at the prompts.
```execute-1
source scripts/set-credentials.sh
```

Make sure the output of the script indicates that the environment variables were properly set.

### GitHub repositories

The workshop requires three GitHub repositories:
- **cat-service** - source code for the cat application and files to automate testing
- **cat-service-release** - copy of the cat application source code, once it has passed testing
- **cat-service-release-ops** - files needed to automate deployment of cat application and postgres db

A script is provided to fork the repos into your own GitHub org and update references to point to your GitHub org and this workshop instance's Docker registry.
> Note: This script uses the [`hub`](https://hub.github.com/) CLI, which uses the GITHUB_USER and GITHUB_TOKEN env vars set above, so it will be able to access your GitHub account.

Run the following command.
```execute-1
source scripts/fork-repos.sh
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

> TODO:
> 1. Update to us [gh](https://github.com/cli/cli) instead of hub ????
>
> 2. Figure out how to use gh help secret set
>
> 3. change to `git clone -b 1.0`

```shell
gh secret set GIT_USERNAME -b"${GITHUB_USER}" --org=${GITHUB_ORG} --repos ${GITHUB_ORG}/cat-service
gh secret set GIT_PASSWORD
```