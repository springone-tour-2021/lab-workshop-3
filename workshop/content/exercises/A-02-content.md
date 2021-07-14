## Run the app locally

Let's begin by running the application locally to understand its behavior.

In both terminal windows, navigate into the cat-service directory.
```execute-all
cd ~/cat-service
clear
```

Cats need somewhere to live, similarly cat service requires a database to store cat information.
The following command will download a [bitnami](https://bitnami.com/) postgres container and start it on the local docker daemon.
The process will run in the background ("detached" mode).
```execute-1
docker run -d --rm --name my-postgres \
       -p 5432:5432 \
       -e POSTGRESQL_USERNAME=bk \
       -e POSTGRESQL_DATABASE=bk \
       -e POSTGRESQL_PASSWORD=bk \
       bitnami/postgresql:latest
```

### Next, start the app.
This may take a couple of minutes as Java dependencies are downloaded for the first time.
```execute-2
./mvnw spring-boot:run \
      -Dspring-boot.run.arguments=--spring.main.cloud-platform=none
```

### While we wait, let meow look at our Cat service app

To be the cats meow we need at a cat, this feline wil need at leaest a name, birthday, age and a few other things. Feel free to see the class that makese our cats.
```open-dashboard
file: ~/cat-service/src/main/java/com/example/demo/Cat.java
```

In this file you will find 3 Assert statements that we use for Testing. The next action button shows an example of one such `Assert` statement used in testing Cats. This like the Cat in line 45 but includes an id to facilitate testing.
```editor:select-matching-text
file: ~/cat-service/src/main/java/com/example/demo/Cat.java
text: 'Assert'
after: 2
```

For example, adopting a new Toby Cat into the db, when Toby is created a test Cat is also made and tagged for testing.
```editor:select-matching-text
file: ~/cat-service/src/main/resources/backup/data.sql
text: 'Toby'
after: 2
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
