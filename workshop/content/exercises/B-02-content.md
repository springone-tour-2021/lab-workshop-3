## Persisting persistent Cats

The meowtivation for these tests it to verify Cat's state remains when persisted as database entries.
Cats and other entities must have an `@Entity` annotation at the class level to signal that they are eligible for persistence.

Click below to view the usage of `@Entity` in context:

```editor:select-matching-text
file: ~/cat-service/src/main/java/com/example/demo/Cat.java
text: "@Entity"
```

Today, we're storing Cats in relational database (RDBMS) tables. Thus, there needs to be an `@Table` annotation present which tells Spring JPA the name of the database table. Let's explore this class markup a little further.

```editor:select-matching-text
file: ~/cat-service/src/main/java/com/example/demo/Cat.java
text: '@Table(name = "cat")'
```

Since RDBMS's have a notion of [primary keys](https://en.wikipedia.org/wiki/Primary_key), we need to suffice the engine with a marker and its strategy.  

The `id` field has been annotated with `@Id` to denote it is the holder of the primary key, while `@GeneratedValue` tells the engine how the key gets generated. Usually, this means a monotonically incrementing value or something specific to the RDBMS, like a UUID. Check out [the JEE docs](https://docs.oracle.com/javaee/7/api/javax/persistence/TableGenerator.html) for more details on its use!

Click below to see property persistence configuration in context:

```editor:select-matching-text
file: ~/cat-service/src/main/java/com/example/demo/Cat.java
text: '@Id'
after: 2
```

For the remainder of the Cat class, you will notice several (non-JUnit) `Assert` statements for throwing Exceptions on improper input. This *style* of code - Design By Contract (DBC) - is enabled by Spring Framework's `org.springframework.util` package.  The concept of DBC has been used as a reference about code quality and is one of the optimal techniques of software construction of object-oriented systems. 

Although not a requirement, this workshop makes use of this convention to ensure proper testing as well as production state consistency. 

## Testing persistence read/write

Let's focus on testing the behaviour when a Cat gets stored and retrieved. To do this, we will use both [TestEntityManager](https://docs.spring.io/spring-boot/docs/current/api/org/springframework/boot/test/autoconfigure/orm/jpa/TestEntityManager.html) and an embedded RDBMS engine. The `TestEntityManager` provides just enough `EntityManager` to be useful in typical store and retrieve situations.

To enable both, mark a test class with [@DataJpaTest](https://docs.spring.io/spring-boot/docs/current/api/org/springframework/boot/test/autoconfigure/orm/jpa/DataJpaTest.html) annotation. This will ensure our test only encompasses the JPA persistence layer with the following behaviour as described in the docs: 
`Using this annotation will disable full auto-configuration and instead apply only configuration relevant to JPA tests.`. Thus, do not expect any other non-JPA (e.g. Web) components to function as they simply won't
get configured. This also means any dependent services need to be explicitly configured or mocked.

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

There is also the necessary classpath dependency for a test-scoped "embedded" database.
An embedded database runs in-memory (aka inside the same Cats app java process), so it enables us to test Cats without having to start up a separate database.
In this case we are using a database called [h2](https://www.h2database.com/html/main.html). 

Let's take a look:

```editor:select-matching-text
file: ~/cat-service/pom.xml
text: "<groupId>com.h2database</groupId>"
before: 1
after: 3
```

Next, we need to specify the connections of the persistence (JPA) engine. Spring accepts a datasource URL property which gets fed to the h2 engine. The h2 engine accepts various parameters through such URL. In this case, it means we get to control the mode for which SQL gets interpreted. For more comprehensive configuration options, please read the [h2 docs](http://www.h2database.com/html/features.html).

Click to see an h2 datasource URL in context:

```editor:select-matching-text
file: ~/cat-service/src/test/resources/application-test.properties
text: "spring.datasource.url=jdbc:h2:~/test;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE"
after: 2
```

This configuration will instruct `h2` to act like an embedded PostgreSQL - perfect for quick and lithe tests.

### Enter the CatRepository

We are not complete with basic save/find tests. The CatsService uses a JpaRepository - `CatsRepository` - thus its interaction will need to play out in tests. Luckily, it follows pretty close to the previous test with a couple differences. Let's see in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsRepositoryTests.java
text: "private CatsRepository repository;"
before: 1
```

A `CatsRepository` is autowired into the `CatsRepositoryTests` class through constructor injection. The `CatsRepository` receives an EntityManager in the form of TestEntityManager. Thus, it is easy to isolate failure if the repository fails a test that is not caused by the EntityManager. The resulting test case is a straightforward save and find through the repository methods.

See the repository test in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsRepositoryTests.java
text: "void findByNameShouldReturnName()"
before: 1
after: 3
```

### Flying cats (database versioning)

For these Repository Tests, you'll notice that DBMS schema and data-state is lacking. To mitigate playing cat-and-mouse, we will explore  how `flyway` manages database state in test.

We want to add `flyway` as a dependency in both test and production scopes so that we always get the same database schema. Using `flyway` as a version control for the database we can test the database before it reaches production to prevent many unwanted scenarios. Like the common problem of multiple developers writing and moving data around like tangled yarn that can cause a _hiss_-y-fit. With `flyway` you can do something like using a clean copy of production data at a chosen state to test against.

Click to see the `flyway` dependency in context:
```editor:select-matching-text
file: ~/cat-service/pom.xml
text: "org.flywaydb"
before: 1
after: 3
```

 The main principle at work here is that `flyway` migrations run during our test cycle. This means that files in `src/main/resources/db.migration` get executed prior to test runs, but after `h2` or other DBMS starts up.

Click below to see the `flyway` database beginning state file:
```editor:open-file
file: ~/cat-service/src/main/resources/db/migration/V1__cat_with_age.sql
```

This is the first database `version migration` file - enumerated v1, v2, etc... - which sets up schema but incompatible with our code base. A second version has been created that alters v1 such that Cat's age is represented as `date` rather than `int`.

Click below to see `flyway` database migration v2 in context:
```editor:open-file
file: ~/cat-service/src/main/resources/db/migration/V2__cat_with_date_of_birth.sql
```

The good news is that our tests are certified against ***real*** database schema Versions. `Flyway` migrations affect tests routines as well as production. However, if you remove `flyway`, then this action ceases to happen, and tests fail - as will Production. Thus `flyway` has indeed become a vital component to `JPA` or `DBMS` tests, as well as production executions.

### Testing the CatsService

Further upstream we have the `CatsService` - responsible for exposing application persistence. The service accepts a repository, which depends on JPA. However, we won't have a JPA engine at THIS test; the JPA tests are completed earlier. Further up the cat test pyramid is where we are!

Filling in for `CatsRepostory`, [Mockito](https://site.mockito.org/) can proxy the instance to return custom (test) Cat beans during test. This is as simple as applying Mockito to the repository bean in a `before` method that will get called at the beginning of each test. Take a look at how this works in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsServiceTests.java
text: "void setup() {"
before: 1
after: 3
```

Once we have the mock component setup, we can focus on its behaviour. Usually mock behaviour is configured at each test site. Thus, it is trivial to deduce the mocking behaviour when reviewing later. Let's have a look at the mock setup and test assertion in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsServiceTests.java
text: "void getCatShouldReturnCat() {"
before: 1
after: 3
```

Paws or no paws. That is a pretty complete set of tests of the persistence and service layer. Let's move on to testing the Web Layer.

### Cats REST Controller 

Another layer of our testing regimen is the HTTP REST endpoint - web tests. Similar to the previous JPA tests, the point here is to ensure quickly that the REST endpoint performs how we think it should - unlike most cats. 

Likewise, this test is still quite low on the pyramid - closer to Integration than Unit tests, but not quite Complete Integration since all resources are not available. This means that those resources we aren't testing are going to be mocked.

Let's take a look at the REST Controller first. We can find out what the production behaviour is like since the code is available. Then we can focus on testing it.

Click below to see the CatsRestController in context:

```editor:select-matching-text
file: ~/cat-service/src/main/java/com/example/demo/CatsRestController.java
text: "@RestController"
after: 14
```

What we know is that the Controller and all endpoints underneath respond on `/cats`. Then we have an endpoint  responding to the `/{name}` path whereas `{name}` is simply replaced with the URI path text - e.g. `/toby`. Furthermore, a request to URI with pattern `/cats/{name}` will respond with a single `Cat` object (JSON encoded). 

### Cat scratch test REST

Time to model a test after the endpoint behaviour. The test should perform exactly all the code paths that the Controller will execute in Production. We are not concerned with the wiring of the JPA repository since it's been tested at an adjacent point in the test-pyramid. To prove the point, the docs state `"Typically @WebMvcTest is used in combination with @MockBean or @Import to create any collaborators required by your @Controller beans"`. Stubbing the service guarantees we will see a result that exercises Controller code and nothing more.

Since we are testing the Web Layer, we will ensure Spring wires up the CatRestController and provide some testing facilities to boot. We can do this using the `@WebMVCTest` annotation which `"disable full auto-configuration and instead apply only configuration relevant to MVC tests "`. 

Click below to see the test class configuration in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsControllerTests.java
text: "@WebMvcTest"
after: 10
```

For this test, we also include mock `CatsService` as prescribed earlier. But also, we include an `ObjectMapper` for translating objects back and forth from JSON encoding, and a `MockMvc` object to communicate with Controller code without using transports (i.e. TCP/IP). This MockMvc component exposes the framework paths leading to our code transparently and directly - there is no transport logic in our code - which reduces the time necessary to complete tests.

Let's focus on the test itself. Using the mock CatsService we can return a real Cat result when called, but we also transform that into a JSON blob using ObjectMapper. Let's see this more in depth.

Click below to see the Controller test case in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsControllerTests.java
text: "getByNameShouldReturnCat"
after: 10
before: 1
```

This mock performs the task of calling our endpoint controller at `"/cats/Toby"` and receiving its response. MockMVC provides all the necessary DSL methods to enable us to control the request and verify the response. Using `MockMvcRequestBuilders` is the preferred way to ensure we build a proper HTTP request, while its `expect` methods
enable us to validate all result criteria for HTTP (i.e. status, headers, content etc...).

## Next steps

Now we are ready for full Integration tests using TestContainers to assist our REST service with a real JPA functionality, real CatsService, and actual HTTP server. Let's go!