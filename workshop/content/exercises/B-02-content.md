## Persisting persistant Cats

The meowtivation for these tests it to verify Cats state remains when persisted as RDBMS entries. Cats and other entities must have an `@Entity` annotation at the class level that tells our program it is eligible for persistence.

Click below to view the usage of `@Entity` in context:

```editor:select-matching-text
file: ~/cat-service/src/main/java/com/example/demo/Cat.java
text: "@Entity"
```

Today, we're storing Cats in RDBMS tables. Thus, there needs to be a `@Table` annotation present which tells Spring JPA the name a database table. Lets explore this class markup a little further.

```editor:select-matching-text
file: ~/cat-service/src/main/java/com/example/demo/Cat.java
text: '@Table(name = "cat")'
```

Since RDBMS's have a notion of [primary keys](https://en.wikipedia.org/wiki/Primary_key) that we need to suffice the engine with a marker and it's strategy.  

The `id` field has been annotated with `@Id` to denote it is the holder of the primary key, while `@GeneratedValue` tells the engine how the key gets generated. Usually, this means an monotonically incrementing value or something specific to the DMBS like a UUID. Check out [the JEE docs](https://docs.oracle.com/javaee/7/api/javax/persistence/TableGenerator.html) for more details on it's use!

Click below to see property persistence configuration in context:

```editor:select-matching-text
file: ~/cat-service/src/main/java/com/example/demo/Cat.java
text: '@Id'
after: 2
```

## Testing Persistence Read / Write

Now under test is the behaviour for when a Cat get stored and retrieved. To do this, we will use both [TestEntityManager](https://docs.spring.io/spring-boot/docs/current/api/org/springframework/boot/test/autoconfigure/orm/jpa/TestEntityManager.html) and an embedded RDBMS engine. The `TestEntityManager` provides enough `EntityManager` to be useful in typical store and retrieve situations.

To enable both, mark a test class with [@DataJpaTest](https://docs.spring.io/spring-boot/docs/current/api/org/springframework/boot/test/autoconfigure/orm/jpa/DataJpaTest.html) annotation. This will ensure our test only encompasses the JPA persistence layer with the following behaviour as described in the docs: 
`Using this annotation will disable full auto-configuration and instead apply only configuration relevant to JPA tests.`. Thus, do not expect any other non-JPA (e.g. Web) components to function as they simply wont
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

There is also the necessary test-scoped dependency in `h2` on the classpath. Lets take a look:

```editor:select-matching-text
file: ~/cat-service/pom.xml
text: "<groupId>com.h2database</groupId>"
before: 1
after: 3
```

Next, we need to specify the connections of the persistence (JPA) engine. Spring accepts a datasource URL property which gets fed to the h2 engine. The h2 engine accepts various parameters through such URL. In this case, it means we get to control the mode which SQL gets interpreted. For more comprehensive configuration options, please read the [h2 docs](http://www.h2database.com/html/features.html).

Click to see an h2 datasource URL in context:

```editor:select-matching-text
file: ~/cat-service/src/test/resources/application-test.properties
text: "spring.datasource.url=jdbc:h2:~/test;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE"
after: 2
```

This configuration will instruct `h2` to act like an embedded PostgreSQL - perfect for quick and lithe tests.

### Enter the CatRepository

We are not complete with basic save find tests. The CatsService uses a JpaRepository - `CatsRepository` - thus it's interaction will need to play out in tests. Luckily, it follows pretty close to the previous test with a couple differences. Lets see in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsRepositoryTests.java
text: "private final CatsRepository repository;"
before: 1
after: 4
```

A `CatsRepository` is autowired into the `CatsRepositoryTests` class through constructor injection. The `CatsRepostory` receives an EntityManager in the form of TestEntityManager. Thus, it is easy to isolate failure if the repository fails a test not caused by the EntityManager. The resulting test case is a straight forward save and find through the repository methods.

See the repository test in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsRepositoryTests.java
text: "void findByNameShouldReturnName()"
before: 1
after: 3
```

*** More Cats mean a Bigger Test Pyramid

### Testing the Service

Further upstream we have the `CatsService` which gets the job of exposing application persistence. The service accepts a repository, which depends on JPA. However, we wont have a JPA engine at test here; the JPA tests are complete. Further up the cat test pyramid is where we are.

filling in for `CatsRepostory`, [Mockito](https://site.mockito.org/) can proxy the instance to return custom (test) Cat beans during test. This is as simple as applying Mockito to the repository bean in a 'before' method that will get called at the beginning of each test. Take a look at how this works in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsServiceTests.java
text: "void findByNameShouldReturnName()"
before: 1
after: 3
```

Once we have the mock component setup, we can focus on it's behaviour. Usually mock behaviour is configured at each test site. Thus it is trivial to deduce the mocking behaviour when reviewing later. lets have a look at the mock setup and test assertion in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/CatsServiceTests.java
text: "void getCatShouldReturnCat() {"
before: 1
after: 3
```

Paws or no paws. That is a pretty complete set of tests of the persistence and service layer. Lets move on to testing the Web Layer.