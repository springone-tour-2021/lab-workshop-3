## Run locally

### Cats, Cats, Everywhere

Throughout this workshop, you will be using an application that returns cat names and ages.

The application comprises a Spring Boot app and a database:
- cat-service - Exposes an enpoint "/cats/{name}" and returns the cat's name and age in months.
- cat-postgres - Stores the names and birth dates of cats.

### Run the app locally

Let's begin by running the application locally to understand its behavior.

> TODO: change to `git clone -b 1.0`

Start by cloning the application:
```execute-1
git clone https://github.com/booternetes-III-springonetour-july-2021/cat-service.git
```

Navigate into the cloned repo in both terminal windows.
```execute-all
cd cat-service
```

List the contents of the repository.
You will see the contents of a typical Spring Boot application.
```execute-1
ls -l
```

Your output will show:
```
-rw-r--r--  1 eduk8s  root    260 Jul  3 22:01 README.md
drwxr-xr-x  3 eduk8s  root     96 Jul  3 22:01 bin
-rw-r--r--  1 eduk8s  root      4 Jul  3 22:01 bump
-rwxr-xr-x  1 eduk8s  root  10070 Jul  3 22:01 mvnw
-rw-r--r--  1 eduk8s  root   6608 Jul  3 22:01 mvnw.cmd
-rw-r--r--  1 eduk8s  root   7618 Jul  3 22:01 pom.xml
drwxr-xr-x  4 eduk8s  root    128 Jul  3 22:01 src
```

> TODO: Add steps to start app and test rest controller

## Next Steps

In the next exercises, you will explore the unit and integration testing that has been incorporated into the app.

> TODO: Add steps to explain unit tests, contract tests (download client and show client side of contract test), flyway, and testcontainers. Add steps for users to run each test and track the outcomes.
