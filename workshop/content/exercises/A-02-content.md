## Run the app locally

Let's begin by running the application locally to understand its behavior.

In both terminal windows, navigate into the cat-service directory.
```execute-all
cd ~/cat-service
clear
```

Cat service requires a database to store cat information.
The following command will download a postgres container from Docker Hub and start it on the local docker daemon.
The process will run in the background ("detached" mode).
```execute-1
docker run -d --rm --name my-postgres \
       -p 5432:5432 \
       -e POSTGRESQL_USERNAME=bk \
       -e POSTGRESQL_DATABASE=bk \
       -e POSTGRESQL_PASSWORD=bk \
       bitnami/postgresql:latest
```

Next, start the app.
This may take a couple of minutes as Java dependencies are downloaded for the first time. Additionaly, the testing artifacts are generated and installed locally.
```execute-2
./mvnw clean install spring-boot:run \
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

You should see a successful response including Tobys' age in months. Toby is the only cat in the database, so you'll get the same response for every request.

## Stop the app

Stop the app.
```execute-2
<ctrl-c>
```

Stop the database.
```execute-1
docker stop my-postgres
```

## Next Steps

In the next exercises, you will explore the unit and integration testing that has been incorporated into the app.
