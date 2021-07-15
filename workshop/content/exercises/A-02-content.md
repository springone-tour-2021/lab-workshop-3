## Run the app locally

Let's begin by running the application locally to understand its behavior.

In both terminal windows, navigate into the cat-service directory.
```execute-all
cd ~/cat-service
clear
```

Cat service requires a database to store cat information.
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

Click the following action block to start the app.
This may take a couple of minutes as Java dependencies are downloaded for the first time.
Go on to the next instruction in the meantime.
```execute-2
./mvnw spring-boot:run \
      -Dspring-boot.run.arguments=--spring.main.cloud-platform=none
```

### While you wait...

Take a look at the class that makes our cats.
This fine feline will need a name and birthday, at the very least.
```editor:open-file
file: ~/cat-service/src/main/java/com/example/demo/Cat.java
```

To be the cat's meow, you'll want to make sure this Cat passes inspection.
Notice the three Assert statements. You will use these for testing.
Click this action block to highlight an example.
Compare it to the Cat in line 45.
This one includes an id to facilitate testing (line 39 versus 45).
```editor:select-matching-text
file: ~/cat-service/src/main/java/com/example/demo/Cat.java
text: 'Assert'
after: 2
```

While cats are solitary by nature, they can also form deep friendships.
You'll want to test any new cat before you adopt it.
For this, any time you add a cat, a test Cat (a copycat!) is also made and tagged for testing.
The new Cat must pass the assertions before it can join the colony.
```editor:select-matching-text
file: ~/cat-service/src/main/resources/backup/data.sql
text: 'Toby'
after: 2
```

### Are we there yet?

When the app has started, you will see the last line of logging as follows:
```
Application availability state ReadinessState changed to ACCEPTING_TRAFFIC
```

Send a request.
```execute-1
http :8080/cats/Toby
```

You should see a successful response including Tobys' age in months. Toby is the only cat in the town, so you'll get the same response for every request.

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
