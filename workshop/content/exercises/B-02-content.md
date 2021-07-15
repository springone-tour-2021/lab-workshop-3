## Persisting persistent Cats

The meowtivation for these next tests is to verify Cat's state remains when persisted as database entries.
Cats and other entities must have an `@Entity` annotation at the class level to signal that they are eligible for persistence.

Click below to view the usage of `@Entity` in context:

```editor:select-matching-text
file: ~/cat-service/src/main/java/com/example/demo/Cat.java
text: "@Entity"
```

Today, we're storing Cats in relational database (RDBMS) tables. Thus, there needs to be a `@Table` annotation present which tells Spring JPA the name of the database table. Let's explore this class markup a little further.

```editor:select-matching-text
file: ~/cat-service/src/main/java/com/example/demo/Cat.java
text: '@Table(name = "cat")'
```

Since RDBMSs have a notion of [primary keys](https://en.wikipedia.org/wiki/Primary_key), we need to supply the engine with a marker and its strategy.

The `id` field has been annotated with `@Id` to denote that it is the holder of the primary key, while `@GeneratedValue` tells the engine how the key gets generated. Usually, this means a monotonically incrementing value or something specific to the RDBMS, like a UUID. Check out [the JEE docs](https://docs.oracle.com/javaee/7/api/javax/persistence/TableGenerator.html) for more details on its use!

Click below to see property persistence configuration in context:

```editor:select-matching-text
file: ~/cat-service/src/main/java/com/example/demo/Cat.java
text: '@Id'
after: 2
```

For the remainder of the Cat class, you will notice several (non-JUnit) `Assert` statements for throwing Exceptions on improper input. This *style* of code—Design By Contract (DBC)—is enabled by Spring Framework's `org.springframework.util` package.
The concept of DBC has been used as a reference about code quality and is one of the optimal techniques of software construction for object-oriented systems. 

Though not a requirement, this workshop makes use of this convention to ensure proper testing as well as production state consistency. 

## Testing read/write persistence

Let's focus on testing the behaviour when a Cat is stored and retrieved. To do this, we will use both [TestEntityManager](https://docs.spring.io/spring-boot/docs/current/api/org/springframework/boot/test/autoconfigure/orm/jpa/TestEntityManager.html) and an embedded RDBMS engine. The `TestEntityManager` provides just enough `EntityManager` to be useful in typical store-and-retrieve situations.

To enable both, mark a test class with [@DataJpaTest](https://docs.spring.io/spring-boot/docs/current/api/org/springframework/boot/test/autoconfigure/orm/jpa/DataJpaTest.html) annotation. This will ensure our test only encompasses the JPA persistence layer with the following behaviour as described in the docs: 
`Using this annotation will disable full auto-configuration and instead apply only configuration relevant to JPA tests`. Thus, do not expect any other non-JPA (e.g. Web) components to function as they simply won't get configured. 
This also means any dependent services need to be explicitly configured or mocked.

Click below to see test class configuration in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsEntityTests.java
text: "@DataJpaTest"
after: 1
```

The actual test is quite simple: save, find, then verify state. The `testEntityManager` makes this simple by exposing a method [persistFlushFind](https://docs.spring.io/spring-boot/docs/current/api/org/springframework/boot/test/autoconfigure/orm/jpa/TestEntityManager.html) specifically for validating save/find operations.

Click below to see a TestEntityManager-based test in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsEntityTests.java
text: "void catCanBePersisted() {"
before: 1
after: 3
```

### Configuring RDBMS-in-test for Cats

We will need a test-scoped, embedded database dependency on the classpath.
An embedded database runs in-memory (aka inside the same java process as the application), so it enables us to test Cats without having to start up a separate database.
In this case we are using a database called h2. 

Let's take a look:

```editor:select-matching-text
file: ~/cat-service/pom.xml
text: "<groupId>com.h2database</groupId>"
before: 1
after: 3
```

Next, we need to specify the connections of the JPA (persistence) engine. Spring accepts a datasource URL property which gets fed to the h2 engine. The h2 engine accepts various parameters through such URLs. In this case, it means we get to control the mode in which SQL gets interpreted. For more comprehensive configuration options, please read the [h2 docs](http://www.h2database.com/html/features.html).

Click to see an h2 datasource URL in context:

```editor:select-matching-text
file: ~/cat-service/src/test/resources/application-test.properties
text: "spring.datasource.url=jdbc:h2:~/test;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE"
after: 2
```

This configuration will instruct `h2` to act like an embedded PostgreSQL—perfect for quick and lithe tests.

### Enter the CatRepository

We are not complete with basic save/find tests. The CatsService uses a JpaRepository—`CatsRepository`—thus its interaction will need to play out in tests. Luckily, it follows pretty close to the previous test with a couple differences. Let's see this in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsRepositoryTests.java
text: "private CatsRepository repository;"
before: 1
```

A `CatsRepository` is autowired into the `CatsRepositoryTests` class through constructor injection. The `CatsRepository` receives an EntityManager in the form of TestEntityManager. Thus, it is easy to isolate failure if the repository fails a test that is not caused by the EntityManager. The resulting test case is a straightforward save-and-find through the repository methods.

See the repository test in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsRepositoryTests.java
text: "void findByNameShouldReturnName()"
before: 1
after: 3
```

### Flying cats (database versioning)

For these Repository tests, you'll notice that RDBMS schema and data-state is lacking. To mitigate playing cat-and-mouse, we will explore  how `flyway` manages database state in test.

We want to add `flyway` as a dependency in both test and production scopes so that we always get the same database schema. Using `flyway` as a version control for the database, we can test the database before it reaches production. This prevents many unwanted scenarios, like the common problem of multiple developers writing and moving data around like tangled yarn that can cause a *hiss*yfit. With `flyway` you can use a clean copy of production data at a chosen state to test against.

Click to see the `flyway` dependency in context:
```editor:select-matching-text
file: ~/cat-service/pom.xml
text: "org.flywaydb"
before: 1
after: 3
```

 The main principle at work here is that `flyway` migrations run during our test cycle. This means that files in `src/main/resources/db.migration` get executed prior to test runs, but after `h2` or another RDBMS starts up.

Click below to see the `flyway` database beginning state file:
```editor:open-file
file: ~/cat-service/src/main/resources/db/migration/V1__cat_with_age.sql
```

This is the first database `version migration` file (named v1). It sets up a schema, but this schema is incompatible with our latest codebase. A second version (named v2) has been created that alters v1 such that Cat's age is represented as `date` rather than `int`.

Click below to see `flyway` database migration v2 in context:
```editor:open-file
file: ~/cat-service/src/main/resources/db/migration/V2__cat_with_date_of_birth.sql
```

The good news is that our tests are certified against ***real*** database schema versions. `Flyway` migrations affect not only test routines, but also the production database itself. Thus `flyway` has become a vital component to `JPA` or `RDBMS` tests, as well as production executions.

### Testing the CatsService

Further upstream we have the `CatsService`—responsible for exposing application persistence. The service accepts a repository, which depends on JPA. However, we won't have a JPA engine at THIS test; the JPA tests are completed earlier.

Filling in for `CatsRepostory`, [Mockito](https://site.mockito.org/) can proxy the instance to return custom (test) Cat beans during test. This is as simple as applying Mockito to the repository bean in a `Before` method that will get called at the beginning of each test. Take a look at how this works in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsServiceTests.java
text: "void setup() {"
before: 1
after: 3
```

Once we have the mock component set up, we can focus on its behaviour. Usually mock behaviour is configured at each test site. Thus, it is trivial to deduce the mocking behaviour when reviewing later. Let's have a look at the mock setup and test assertion in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsServiceTests.java
text: "void getCatShouldReturnCat() {"
before: 1
after: 3
```

Paws or no paws, that is a pretty complete set of tests of the persistence and service layer. Let's move on to testing the Web Layer.

### Cats REST Controller 

Another layer of our testing regimen is the HTTP REST endpoint: web tests. Similar to the previous JPA tests, the point here is to ensure quickly that the REST endpoint behaves the way we think it should—unlike most cats. 

Likewise, this test is still quite low on the pyramid—closer to Integration than Unit tests, but not quite "Complete Integration" since not all resources are available—these are component tests indeed. This means that the resources we aren't testing need to be mocked.

Let's take a look at the REST Controller first. We can find out what the production behaviour is like since the code is available. Then we can focus on testing it.

Click below to see the CatsRestController in context:

```editor:select-matching-text
file: ~/cat-service/src/main/java/com/example/demo/CatsRestController.java
text: "@RestController"
after: 14
```

What we know is that the Controller and all endpoints underneath respond on `/cats`. Then we have an endpoint  responding to the `/{name}` path whereas `{name}` is simply replaced with the URI path text—e.g. `/Toby`. Furthermore, a request to URI with pattern `/cats/{name}` will respond with a single `Cat` object (JSON encoded). 

### Catnap (REST) test

Time to model a test after the endpoint behaviour. The test should perform exactly all the code paths that the Controller will execute in production. We are not concerned with the wiring of the JPA repository since it has been tested at an adjacent point in the test pyramid. To prove the point, the docs state `"Typically @WebMvcTest is used in combination with @MockBean or @Import to create any collaborators required by your @Controller beans"`. Stubbing the service guarantees we will see a result that exercises Controller code and nothing more.

Since we are testing the Web Layer, we will ensure Spring wires up the CatRestController and provides some testing facilities to boot. We can do this using the `@WebMVCTest` annotation which will `"disable full auto-configuration and instead apply only configuration relevant to MVC tests "`. 

Click below to see the test class configuration in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsControllerTests.java
text: "@WebMvcTest"
after: 10
```

For this test, we also include a mock `CatsService` as prescribed earlier. We further add an `ObjectMapper` for translating objects back and forth from JSON encoding, as well as a `MockMvc` object to communicate with Controller code without using transports (i.e. TCP/IP).
This MockMvc component transparently and directly exposes the framework paths leading to our code, sans transport (TCP) specifics. This make tests faster.

Let's focus on the test itself. Using the mock CatsService we can return a real Cat result when called, but we also transform that into a JSON blob using ObjectMapper. Let's see this more in depth.

Click below to see the Controller test case in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsControllerTests.java
text: "getByNameShouldReturnCat"
after: 10
before: 1
```

This mock performs the task of calling our endpoint controller at `"/cats/Toby"` and receiving its response. MockMVC provides all the necessary DSL methods to enable us to control the request and verify the response. Using `MockMvcRequestBuilders` is the preferred way to ensure we build a proper HTTP request, while its `expect` methods
enable us to validate all result criteria for HTTP (status, headers, content, etc).

## Next steps

Now we are ready for full Integration tests using Testcontainers to assist our REST service with real JPA functionality, real CatsService, and an actual HTTP server. Let's go!
