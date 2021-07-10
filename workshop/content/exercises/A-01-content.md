## Cats, Cats, Everywhere

Throughout this workshop, you will be using an application that returns cat names and ages.

The application comprises a Spring Boot app and a database:
- **cat-service** - Exposes an enpoint "/cats/{name}" and returns the cat's name and age in months.
- **cat-postgres** - Stores the names and birth dates of cats.

## Prerequisites

You will need a [GitHub account](https://github.com).

### Fork & clone the repos

Open the GitHub UI in a browser and log in.
Fork the following two repos.
- **cat-service** contains the source code for the cat-service application
- **cat-service-release-ops** - contains manifests for deployment to Kubernetes for cat-service and postgres db

```dashboard:open-url
url: https://github.com/booternetes-III-springonetour-july-2021/cat-service
```

```dashboard:open-url
url: https://github.com/booternetes-III-springonetour-july-2021/cat-service-release-ops
```
 
Copy the following line to the terminal.
Replace "<my-github-org>" with your org name (the bit in the url after github.com; often the same as your username).
Storing the org in an environment variable will help generate commands throughout the workshop.
```copy
export GITHUB_ORG=<my-github-org>
```

Clone your repos to the workshop environment.
```execute-1
git clone https://github.com/$GITHUB_ORG/cat-service
cd cat-service
git checkout educates-workshop

cd ..
git clone https://github.com/$GITHUB_ORG/cat-service-release-ops
cd cat-service-release-ops
git checkout educates-workshop
```
