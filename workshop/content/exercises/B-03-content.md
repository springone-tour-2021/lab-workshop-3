## App Integration Tests with Containers

*** Further up the test pyramid, Cats become meowschievous ***

So far we've been testing against an in-memory database. A more faithful representation of a production system would be a database that is external to the application. How can we achieve this without taking on the burden of managing a separate database. [Testcontainers](https://www.testcontainers.org) to the rescue! Testcontainers is a Java library that supports JUnit tests and launches instances of common databases as Docker containers on the local Docker daemon.

## Add Testcontainers dependency

The entrypoint for getting Testcontainers working is through `pom.xml`. Simply add the necessary `testcontainers` dependency to the project under `test` scope. Testcontainers make available many modules for getting your flavor of RDBMS in test. See a listing of what's there now [on their website](https://www.testcontainers.org/modules/databases/). This workshop uses a [Postgres](https://www.testcontainers.org/modules/databases/postgres/) module for testing—we will explore its API shortly. 

First, let's take a peek at the dependency inclusion for our build:

```editor:select-matching-text
file: ~/cat-service/pom.xml
text: "<groupId>org.testcontainers</groupId>"
before: 1
after: 4
```

### Cats love Testcontainers

With the dependency in hand, we can issue configuration to our next test class `CatsIntegrationTests`. 

In this test, we will enable Testcontainers and allow Spring Boot to classpath-scan our entity and service objects. This is accomplished with 2 annotations: `@Testcontainers` and `@SpringBootTest`. The former is a JUnit Jupiter extension that activates automatic startup and shutdown of containers used during a test case. The latter annotation activates Spring Boot's classpath scanning for our Spring-related configuration objects; we want the whole application to find RDBMS and expose real (heavy, transport-laden) REST endpoints for test.

Click to see configuration in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsIntegrationTests.java
text: "@Testcontainers"
after: 1
```

Next, we will need to make the container available to Spring Boot during startup. Adding a static (before class instance) bean of type `org.testcontainers.containers.GenericContainer` will allow this to happen. In our case, we want to start a PostgreSQL container, and in our favor there is a specific one available: `org.testcontainers.containers.PostgreSQLContainer`. This sub-class exposes some properties about our `postgres` instance such as port, username, password, etc.

Click the below action to see the container in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsIntegrationTests.java
text: "@Container"
after: 1
```

The test extension (aka `@Testcontainers`) will capture the `@Container` annotated bean and do the work of managing its lifecycle (startup, shutdown, restart, etc). In addition, we need to specify an image parameter to the PostgreSQLContainer. By default, it is `postgres:latest`.

### *Cat*necting to Testcontainers

In order to connect to the container, we must find out how to relay its connectivity details over to our test. This happens at runtime, because we cannot pre-program the specific IP/PORT parameters due to system limitations; a pre-programmed IP/PORT for instance may become invalid sometime before the container starts. This potential cause of intermittent test failure downstream is mitigated by accessing connectivity details AFTER the container has been started.

The `@DynamicPropertySource` annotation enables dynamically adding properties into Spring's Environment during runtime. This annotation requires a static method with a single parameter of type `DynamicPropertyRegistry`. 
Let's take a look at the setup and discuss its functionality below:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsIntegrationTests.java
text: "@DynamicPropertySource"
after: 6
```
The `DynamicPropertyRegistry` is used to add name-value pairs to the core Spring Environment's set of PropertySources used for placeholder and values. Values supplied to the registry are dynamic and provided via a `java.util.function.Supplier` which is only invoked when the property is resolved.
In this case, we have relayed container connection details over to `spring.datasource.` properties. This way, JPA will have all the necessary property values for making a connection to the container-bound Postgres database.

### Testing the REST endpoint

This test represents a fully wired server application. But we want to test the behaviour not of the client, but of the REST endpoint. Thus, we can bring out the `TestRestTemplate`. This object makes it easier to know how an HTTP service under test is behaving. Per the document: `4xx and 5xx do not result in an exception being thrown and can instead be detected via the response entity and its status code`. This is important because we can more easily model expected failure behaviour through HTTP response-state assertions.

Let's see how this works in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsIntegrationTests.java
text: "void getCatSucceeds() {"
before: 1
after: 3
```

The `@SpringBootTest` annotation specifies `webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT` allowing `testRestTemplate` to bind to a real, transport-backed HTTP server. Thus, we can test the controller exposed on '/cats' with our `testRestTemplate`.

Next, we will begin writing tests that ensure client-side (consumer) behaviour is matched between released versions using Spring-Cloud-Contract.