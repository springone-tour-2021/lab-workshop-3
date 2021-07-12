## App Integration Tests with Containers

*** Airs getting thin this far up the Cat Test Pyramid

The entrypoint for getting TestContainers working is through pom.xml. Simply add the `testcontainers` dependency to any project under 'test' scope. Lets take a peek at the pom for `cats-service` example:

```editor:select-matching-text
file: ~/cat-service/pom.xml
text: "<groupId>org.testcontainers</groupId>"
before: 1
after: 4
```

### Cats love TestContainers

With the dependency in hand, we can issue annotations to our next test class `CatsIntegrationTests`. 

Now we need to enable Testcontainers and allow Spring Boot to classpath-scan our entity and service objects. This is accomplished with 2 annotations: `@Testcontainers` and `@SpringBootTest`. The former is a JUnit Jupiter extension that activates automatic startup, and shutdown of containers used during a test case. The latter annotation activates Spring Boots Classpath scanning for our Spring-related configuration objects; we want the whole application to find RDBMS and expose REST endpoints for test.

Click to see configuration in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsIntegrationTests.java
text: "@Testcontainers"
after: 1
```

Next, we will need to make the Container available to Springboot during startup. Adding a static (before class instance) bean of type `org.testcontainers.containers.GenericContainer` will allow this to happen. In our case, we want to startup a PostgreSQL container, and in our favor there is a specific one available: `org.testcontainers.containers.PostgreSQLContainer`.

Click the below action to see the container in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsIntegrationTests.java
text: "@Container"
after: 1
```

The test extenstion AKA `@Testcontainers` will capture the `@Container` annotated bean and do the work of managing its  (startup, shutdown, restart ,etc...) lifecycle. In addition, we need to specify a parameter to the PostgreSQLContainer - some container name in the Docker regisry - by default is 'postgres', but you *may* need a specific version for
your application.

### Catnecting to TestContainers

The next step is a lifecycle issue that will allow Spring to know where the Container resource lives. In this test case 
our Postgres database is started on an unknown port because we cannot specify the port first. That is because we may never know if such port is available. Rather, let the OS/system decide what is available then feed that port to the application.

Using an annotation called `@DynamicPropertySource` for our integration tests, we can fetch the correct port and IP or any other metadata of the running container at runtime, before a test starts. 

Thus, the following block of code executes when the container is ready, and gives our application the knowledge (properties) needed to make a connection to the resource - in this case a PostgreSQL database living in a container.

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsIntegrationTests.java
text: "@DynamicPropertySource"
after: 6
```

This particular instance exposes it's URL, username and password through the PostgreSQLContainer's instance that we will use to make the connection at runtime. Then the DynamicPropertySource gets filled in and merged with Spring's Environment's set of PropertySources.

### Integration testing the REST Endpoint

This test represents a fully wired server application. But we want to test the behaviour not of the client, but of the REST endpoint. Thus, we can bring out the `TestRestTemplate` - this object make it easier to know how an HTTP service under test is behaving. Per the document: `4xx and 5xx do not result in an exception being thrown and can instead be detected via the response entity and its status code`. This is important because we can more easily model expected
failure behaviour through HTTP response-state assertions.

Lets see how this works in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsIntegrationTests.java
text: "void getCatSucceeds() {"
before: 1
after: 3
```

The `@SpringBootTest` annotation specifies `webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT` allowing `testRestTemplate` to bind to real transport-backed HTTP server. Thus, we can test the controller exposed on '/cats' with our `testRestTemplate`.

Next, we will begin writing tests that ensure client-side (consumer) behaviour is matched between released versions using Spring-Cloud-Contract.
