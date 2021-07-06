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
source scripts/credentials.sh
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
source scripts/repos.sh
```

In a browser, open [GitHub](https://github.com), and navigate to the list of repositories in your org.
You should see three new repositories:
- `cat-service` - the application code and testing automation files
- `cat-service-release` - copy of the application code, tested and ready to deploy
- `cat-service-release-ops` - deployment files and deployment automation files

You do not need to understand the contents of these repos yet. 
You will go through them as you proceed through this workshop.

### GitHub Actions secrets

The last configuration detail to set up is adding credentials to `cat-service` so that the GitHub Actions in `cat-service` can push a copy of the tested code to `cat-service-release`. To do this:
- In your browser, navigate to the `cat-service` repository
- Navigate to Settings -> Secrets -> New repository secret.
- Create a secret called GIT_USERNAME with your GitHub username as the value
- Create another secret called GIT_PASSWORD with your access token as the value
