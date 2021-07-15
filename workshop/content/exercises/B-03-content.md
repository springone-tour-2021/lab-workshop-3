## App integration tests with containers

*** Further up the test pyramid, Cats become meowschievous ***

The entrypoint for getting Testcontainers working is through `pom.xml`. Simply add the necessary `testcontainers` dependency to the project under `test` scope. Testcontainers make available many modules for getting your flavor of RDBMS in test. See a listing of what's there now [on their website](https://www.testcontainers.org/modules/databases/). This workshop the uses a [postgres](https://www.testcontainers.org/modules/databases/postgres/) module for testing—we will explore its API shortly. 

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

The next step is a lifecycle issue that will allow Spring to know where the container resource lives.
In this test case, our Postgres database is started on an unknown port/IP because we cannot specify any transport first. That is because we may never know if such transport (the IP and port of the container) is available. Rather, let the operating system decide what is available, then feed those connection details to the application.

Using an annotation called `@DynamicPropertySource` for our integration tests, we can fetch the correct connection details (or any other metadata of the running container at runtime) before a test starts. This way, we can map what the container knows about its connectivity to our `spring.datasource` properties.

Thus, the following block of code executes when the container is ready, and gives our application the knowledge (properties) needed to make a connection to the resource—in this case a PostgreSQL database living in a container.

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsIntegrationTests.java
text: "@DynamicPropertySource"
after: 6
```

This particular instance exposes its URL, username, and password through the PostgreSQLContainer's instance that we will use to make the connection at runtime. Then the DynamicPropertySource gets filled in and merged with the Spring Environment's set of PropertySources.

### Integration testing the REST endpoint

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