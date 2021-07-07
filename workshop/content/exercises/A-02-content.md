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
drwxr-xr-x 2 eduk8s root  4096 Jul  6 18:10 bin
-rw-r--r-- 1 eduk8s root     5 Jul  6 18:10 bump
-rwxr-xr-x 1 eduk8s root 10070 Jul  6 18:10 mvnw
-rw-r--r-- 1 eduk8s root  6608 Jul  6 18:10 mvnw.cmd
-rw-r--r-- 1 eduk8s root  7618 Jul  6 18:10 pom.xml
-rw-r--r-- 1 eduk8s root   260 Jul  6 18:10 README.md
drwxr-xr-x 4 eduk8s root  4096 Jul  6 18:10 src
```

Start a postgres database.
The container will run on docker in detached mode (aka in the background).
```execute-1
docker run -d --rm --name my-postgres \
       -p 5432:5432 \
       -e POSTGRES_USER=bk \
       -e PGUSER=bk \
       -e POSTGRES_PASSWORD=bk \
       postgres:latest
```

In the second terminal, start the app.
App startup may take a couple of minutes as Java dependencies are downloaded for the first time.
```execute-2
./mvnw spring-boot:run \
      -Dspring-boot.run.arguments=--spring.main.cloud-platform=none
```

When the app has started, you will see the last line of logging as follows:
```
Application availability state ReadinessState changed to ACCEPTING_TRAFFIC
```

Send a request.
```execute-1
http :8080/cats/Toby
```

You should see a successful response including Tobys' age in months.

### Stop the app

Stop the app.
```execute-2
<ctrl-c>
```

Stop the database.
```execute-2
docker stop my-postgres
```

## Next Steps

In the next exercises, you will explore the unit and integration testing that has been incorporated into the app.
