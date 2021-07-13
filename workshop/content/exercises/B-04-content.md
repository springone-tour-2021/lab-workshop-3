## Consumer Side (contract)Cat Testing

The furst step is to add the `spring-cloud-starter-contract-verifier` dependency that lets us write a test to support the contract verification. Click the action below to show Maven `pom.xml` dependencies in context:

```editor:select-matching-text
file: ~/cat-service/pom.xml
text: "spring-cloud-starter-contract-verifier"
before: 2
after: 2
```

Next, we will setup the maven plugin that allows for both service to contract test exectuion, and contract to stub (contract embodied as a stand-alone mock service) generation. This gives the necessary `verification` steps that ensure the contract works against the service.

```editor:select-matching-text
file: ~/cat-service/pom.xml
text: "spring-cloud-contract-maven-plugin"
before: 2
after: 9
```

Confurguration for the Cats service dictates that we're using JUNIT5 of course, but also we specify a `base class` property. This will get used to transform our contract into the service to contract verification test. 

***It is necessary to keep the contract in sync with REST services - any changes to the REST service must be reflected in related contracts.***

When the verification process succeeds, the plugin will generate a maven artifact that can be used by our client-cat application for running consumer-side tests. Deployment of the artifact is configurable; our application makes use of the local option. We will explore that facet later.

### The Cat Contract

The contract must specify how we expect the REST endpoint to work. This can be done in Groovy or YAML - Cats choose Groovy in this project - cats ARE groovy. Contract definitions are stored in a `contracts` folder within the `test/resources` directory. 

For this Groovy contract, you'll need to make an import to bring in the Contract DSL namespace. Click the action below to see the import in context:

```editor:select-matching-text
file: ~/cat-service/src/test/resources/contracts/shouldReturnAllCats.groovy
text: "import org.springframework.cloud.contract.spec.Contract"
```

Now, begin the initial claws (clause) with `Contract.make`. This method is our point of entry to build the contract and represents the top-level object in the contract specification. Then, we can add a description using the `description` method. It's not required, but it facilitates readability.

Lets begin putting this together. Click the action to see clause and description in context:

```editor:select-matching-text
file: ~/cat-service/src/test/resources/contracts/shouldReturnAllCats.groovy
text: "Contract.make {"
after: 1
```

Now, we can model the request over HTTP. To do this, we'll call the `request` method of our Contract object to begin
shaping the request part. The request must hit a URL using the HTTP verb of the Cat's choice. Click the action to see the request part of the contract in context:

```editor:select-matching-text
file: ~/cat-service/src/test/resources/contracts/shouldReturnAllCats.groovy
text: "request {"
after: 3
```

Next, we want a response that even a Tabby can appreciate. The `response` method is placed adjacent to the `request` object. We can make use of supplemental methods within the `response` object to state what we expect. In this case, it will inspect the HTTP `status` for OK (200), the `contentType` header should specify a `json` payload. Finally, body inspection is possible using json extractions; in this case a `field:value` evaluation occurs.

Click the action to see the response part of the contract in context:

```editor:select-matching-text
file: ~/cat-service/src/test/resources/contracts/shouldReturnAllCats.groovy
text: "response {"
after: 7
```

With the contract definition out of the way, we can write the verification `BaseClass`.

### Verification Base Test

The `BaseClass` sets up the endpoint-under-test to behave as we expected to in the contract definition. This means any changes to contract MUST result in a change to service, and vice versa.

The BaseClass is a simple `@SpringBootTest` that doesn't expose it's own server, but rather exposes a `mock MVC` endpoint through [RestAssured](https://rest-assured.io/). It is `mock` because rather than a full blown server with exposed TCP port, there is ONLY the server-side mechanics without transport - the exact same behaviour but no wire traffic. This makes it quite fast and efficient at running many tests.

Lets take a look at the Cat's BaseClass. This is a simple `@SpringBootTest` kind of test as there are a few parts we will identify and explain as we go further.

Take a look at the BaseClass resource configuration in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/BaseClass.java
text: "private CatsRepository catsRepository;"
before: 1
after: 4
```

First, there's the dependency for the REST service exposed by `CatsRestController`. This Controller needs a `CatsService` instance, which in turn requires a `JPARepository` for Cats - a mock CatsRepository. 

First, `CatRepostory` requires mock behaviour, which can be issued within a `@BeforeEach` method. Finally, the mockMVC component gets configured with the Controller under test handling our requests.

Take a look at the BaseClass mock and MVC configuarion in context.

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/BaseClass.java
text: "@BeforeEach"
after: 5
```

Now, lets heard cats toward the next segment - Client to Stub tests!

## Stubs the Cat (client)

In this section, we will examine the validation of client to server by using the contract stub generated 
perviously. 

Start by cloning a cat-client repository.
```execute-1
cd ~
git clone https://github.com/booternetes-III-springonetour-july-2021/cat-client/cat-client
cd cat-client
```

We will need some pom.xml entries, so lets get started by looking at the necesary
dependencies:

Click to view in context:

```editor:select-matching-text
file: ~/cat-service/pom.xml
text: "spring-cloud-starter-contract-stub-runner"
before: 2
after: 2
```

Adding the `spring-cloud-starter-contract-stub-runner` lets us decare tests bound to a specific stub generated 
through the `verifier` module. From here we can take a quick peek at production to understand whats under
the client hood; the Cat data, how to make that call out, where it goes, and what to make of the result.

Click below to see the client data in context:

```editor:select-matching-text
file: ~/cat-client/src/main/java/com/example/catclient/CatClient.java
text: "class Cat {"
before: 3
after: 3
```

So this is what the client expects in return for a request - hopefully its the same as on server - and if it's not, then we will find out during tests. Now, lets take a look at the client itself; it's a simple `restTemplate` consumer that makes the HTTP callout to our cat service at "/cats/{some cat name}".  

Click below to see the client in context:

```editor:select-matching-text
file: ~/cat-client/src/main/java/com/example/catclient/CatClient.java
text: "public class CatClient {"
before: 1
after: 19
```

This `restTemplate` eventually gets wired in through our appliation configuration.
Click to see this in context:

```editor:select-matching-text
file: ~/cat-client/src/main/java/com/example/catclient/CatClient.java
text: "@Bean"
after: 1
```

From here, we can then understand what our Test will need to do: validate that that call succeeds and the data comes back without missing bits or failure.

### Introducing StubRunner; the fastest cat in the world

To test our client against a real server, we can employ a `Stub Runner` which does the job of finding, downloading and 
executing a contract stub given by an [ivy location](https://ant.apache.org/ivy/history/latest-milestone/concept.html) string. To understand the options and scope of this component - it is quite powerful - please consult the [docs on stub runner](https://cloud.spring.io/spring-cloud-contract/1.2.x/multi/multi__spring_cloud_contract_stub_runner.html) for more information.

Click here to see how we configure the stub runner for Cat (REST) Service in context:

```editor:select-matching-text
file: ~/cat-client/src/test/java/com/example/catclient/CatClientApplicationTests.java
text: "@AutoConfigureStubRunner"
after: 3
```

First, we configure the `ids` property which is in `ivy notation` - per the doc - `" ([groupId]:artifactId[:version][:classifier][:port]). groupId, version, classifier and port can be optional."`. The [docs](https://cloud.spring.io/spring-cloud-contract/reference/html/project-features.html#features-stub-runner-downloading-stub) suggest we have multiple options to find a stub, and in this Cat test we use `local` since our artifact (the sub built by verifier in that last step) will end up in the `.m2` directory.

***By default, Spring Cloud Contract integrates with Wiremock as the HTTP server stub.***

Next, we can write the test as usual.  Remember the stub runner locates and executes our Stub, which is really a [WireMock](http://wiremock.org/) service that models our service; its not the real service, just a static stub of it.
The test simply calls the Cat REST endpoint (the stub) and evaluates that the result is consistent with client's expectations.

Click here to see the cat-client in context:

```editor:select-matching-text
file: ~/cat-client/src/test/java/com/example/catclient/CatClientApplicationTests.java
text: "@SpringBootTest"
after: 12
```

Because this is a `@SpringBootTest`, all client dependencies will be configured as a full application, thus the stub-runner facilitates the server-side (in this case our Wiremock stub).

With the client out of the way, we have come to the conclusion of our test section. Given the success of these tests, we can be confident the cats will always land on their 4 legs! This bring us to the build and deployment phases in the next section.