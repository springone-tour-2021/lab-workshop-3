### Run the app locally

Let's begin by running the application locally to understand its behavior.

In both terminal windows, navigate into the app repo that you cloned & forked earlier.
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

Start a postgres database.
> Note: TODO - is this correct? the app is not connecting in the next step...
```execute-1
docker run -d --rm --name my-postgres -p 5432:5432 -e POSTGRES_USER=bk -e PGUSER=bk -e POSTGRES_PASSWORD=bk postgres:latest
```

Then, in terminal 2, start the app.
```execute-1
./mvnw spring-boot:run
```

Send a request.
```execute-1
http :8080/cats/Toby
```

You should see a successful response including Tobys' age in months.

### Stop the app

Stop the app and the database.
```execute-2
<ctrl-c>

docker stop my-postgres
```


## Next Steps

In the next exercises, you will explore the unit and integration testing that has been incorporated into the app.

> TODO: Add steps to explain unit tests, contract tests (download client and show client side of contract test), flyway, and testcontainers. Add steps for users to run each test and track the outcomes.
