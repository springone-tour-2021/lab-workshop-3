## Cats, Cats, Everywhere

Throughout this workshop, you will be using a Spring Boot application called _Cat Service_ that returns cat names and ages. The app uses a postgres database to store cat information.

#### Prerequisites

You will need a [GitHub account](https://github.com).

### Fork & clone the repos

Open the GitHub UI in a browser and log in.
Fork the following two repos.

**1. cat-service** - app source code
```dashboard:open-url
url: https://github.com/booternetes-III-springonetour-july-2021/cat-service
```

**2. cat-service-release-ops** - app & database deployment files
```dashboard:open-url
url: https://github.com/booternetes-III-springonetour-july-2021/cat-service-release-ops
```

For convenience, store the name of your GitHub org (the bit in the url after github.com; often the same as your username) in an environment variable.
This will help generate commands throughout the workshop.
You do not need to provide your password.

Copy the following line to the terminal and replace `my-org` with your org name (the bit in the url after github.com; often the same as your username).
This will store it in an environment variable and make it easier to generate commands throughout this workshop.
> Don't worry - the value will not be saved or used outside your tutorial session, and you do not need to enter your password.
```copy
export GITHUB_ORG=my-org
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
