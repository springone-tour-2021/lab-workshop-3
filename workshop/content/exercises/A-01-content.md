## Cats, Cats, Everywhere

Throughout this workshop, you will be using an application that returns cat names and ages.

The application comprises a Spring Boot app and a database:
- **cat-service** - Exposes an enpoint "/cats/{name}" and returns the cat's name and age in months.
- **cat-postgres** - Stores the names and birth dates of cats.

## Prerequisites

You will need:
- A GitHub [account](https://github.com)
- A GitHub [personal access token](https://docs.github.com/en/github/authenticating-to-github/keeping-your-account-and-data-secure/creating-a-personal-access-token) (with "repo" and "workflow" access rights)
  
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
- `cat-service-release` - empty for now; tested code will be copied here
- `cat-service-release-ops` - deployment files and deployment automation files

You do not need to understand the contents of these repos yet. 
You will go through them as you proceed through this workshop.
