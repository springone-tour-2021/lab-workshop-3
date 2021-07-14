This section of the workshop introduces a `client` aspect for illustrating the consumer side of Consumer Driven Contract (CDC) testing. To initialize, fork and clone the `cat-client` repository as follows below.

**1. cat-client** - client source code
```dashboard:open-url
url: https://github.com/booternetes-III-springonetour-july-2021/cat-client
```

Clone the `cat-client` repo to the workshop environment:
```execute-1
rm -rf cat-client

git clone https://github.com/$GITHUB_ORG/cat-client && \
    cd cat-client && \
    cd ..
```

### Producer Configuration

The *fur*st step is to add the `spring-cloud-starter-contract-verifier` dependency that lets us write a test to support the contract verification. Click the action below to show Maven `pom.xml` dependencies in context:

```editor:select-matching-text
file: ~/cat-service/pom.xml
text: "spring-cloud-starter-contract-verifier"
before: 2
after: 2
```

Next, we will setup the maven plugin that allows for both service-to-contract (verify service works as stated in the contract) test verification, and contract to stub (contract embodied as a stand-alone mock service) generation.

```editor:select-matching-text
file: ~/cat-service/pom.xml
text: "spring-cloud-contract-maven-plugin"
before: 2
after: 9
```

Con*fur*guration for the Cats service dictates that we're using JUNIT5 of course, but also we specify a `base class` property. This will get used to transform our contract into the service to contract verification test. 

***It is necessary to keep the contract in sync with REST services. Any changes to the REST service must be reflected in related contracts.***

When the verification process succeeds, the plugin will generate a maven artifact that can be used by our client-cat application for running consumer-side tests. Deployment of the artifact is configurable; our application makes use of the local option. We will explore that facet later.

### The Cat contract

The contract must specify how we expect the REST endpoint to work. This can be done in Groovy or YAML—Cats choose Groovy in this project—cats ARE groovy. Contract definitions are stored in a `contracts` folder within the `test/resources` directory. 

For this Groovy contract, you'll need to make an import to bring in the Contract DSL namespace. Click the action below to see the import in context:

```editor:select-matching-text
file: ~/cat-service/src/test/resources/contracts/shouldReturnAllCats.groovy
text: "import org.springframework.cloud.contract.spec.Contract"
```

Now, begin the initial claws (clause) with `Contract.make`. This method is our point of entry to build the contract and represents the top-level object in the contract specification. Then, we can add a description using the `description` method. It's not required, but it facilitates readability.

Let's begin putting this together. Click the action to see clause and description in context:

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

Next, we want a response that even a Tabby can appreciate. The `response` method is placed adjacent to the `request` object. We can make use of supplemental methods within the `response` object to state what we expect. In this case, it will inspect the HTTP `status` for OK (200), the `contentType` header should specify a `json` payload. Finally, body inspection is possible using JSON extractions; in this case a `field:value` evaluation occurs.

Click the action to see the response part of the contract in context:

```editor:select-matching-text
file: ~/cat-service/src/test/resources/contracts/shouldReturnAllCats.groovy
text: "response {"
after: 7
```

With the contract definition out of the way, we can write the verification `BaseClass`.

### Verification base test

The `BaseClass` sets up the endpoint-under-test to behave as we expect it to in the contract definition. This means any changes to contract MUST result in a change to service, and vice versa.

The BaseClass is a simple `@SpringBootTest` that doesn't expose its own server, but rather exposes a `mock MVC` endpoint through [RestAssured](https://rest-assured.io/). It is `mock` because rather than a full blown server with exposed TCP port, there is ONLY the server-side mechanics without transport—the exact same behaviour but no wire traffic. This makes it quite fast and efficient at running many tests.

Let's take a look at the Cat's BaseClass. This is a simple `@SpringBootTest` kind of test as there are a few parts we will identify and explain as we go further.

Take a look at the BaseClass resource configuration in context:

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/BaseClass.java
text: "private CatsRepository catsRepository;"
before: 1
after: 4
```

First, there's the dependency for the REST service exposed by `CatsRestController`. This Controller needs a `CatsService` instance, which in turn requires a `JPARepository` for Cats—a mock CatsRepository. 

First, `CatRepostory` requires mock behaviour, which can be issued within a `@BeforeEach` method. Finally, the mockMVC component gets configured with the Controller under test handling our requests.

Take a look at the BaseClass mock and MVC configuarion in context.

```editor:select-matching-text
file: ~/cat-service/src/test/java/com/example/demo/BaseClass.java
text: "@BeforeEach"
after: 5
```

Now, let's heard cats toward the next segment—Client to Stub tests!

## Stubs the Cat (client)

In this section, we will examine the validation of consumer (client) to producer (service) by using the contract stub generated previously. 

Start by running `install` target to the `service` repo which installs the generated `verifier` stubs as maven artifacts:

```execute-1
cd ~/cat-service ; ./mvnw clean install -DskipTest
```

This step will execute the spring-cloud-contract maven plugin, which generates artifacts and installs them into `.m2` directory (becasue we're using Maven).

Then we can check out what needs to go in our `pom.xml` to enable stub reception at test:
```editor:select-matching-text
file: ~/cat-service/pom.xml
text: "spring-cloud-starter-contract-stub-runner"
before: 2
after: 2
```

Adding the `spring-cloud-starter-contract-stub-runner` let's us declare tests bound to a specific stub generated 
through the `verifier` module. From here we can take a quick peek at client to understand what's under the hood; the Cat data, how to make that HTTP call out, and what to make of the result.

Click below to see the client data in context:

```editor:select-matching-text
file: ~/cat-client/src/main/java/com/example/catclient/CatClient.java
text: "class Cat {"
before: 3
after: 3
```

So this is what the client expects in return for a request—hopefully it's the same as on the server—and if it's not, then we will find out during tests. Now, let's take a look at the client itself; it's a simple `restTemplate` consumer that makes the HTTP callout to our cat service at "/cats/{some cat name}".

Click below to see the client in context:

```editor:select-matching-text
file: ~/cat-client/src/main/java/com/example/catclient/CatClient.java
text: "public class CatClient {"
before: 1
after: 19
```

The `restTemplate` eventually gets wired in through our application configuration.

Click to see this in context:
```editor:select-matching-text
file: ~/cat-client/src/main/java/com/example/catclient/CatClientApplication.java
text: "RestTemplate restTemplate"
before: 1
```

From here, we can then understand what our Test will need to do: validate that that call succeeds and the data comes back without missing bits or failure.

### Introducing StubRunner; the fastest cat in the world

To test our client against a real server, we can employ a `Stub Runner` which does the job of finding, downloading and 
executing a contract stub given by an [ivy location](https://ant.apache.org/ivy/history/latest-milestone/concept.html) string. To understand the options and scope of this component—it is quite powerful—please consult the [docs on stub runner](https://cloud.spring.io/spring-cloud-contract/1.2.x/multi/multi__spring_cloud_contract_stub_runner.html) for more information.

Click here to see how we configure the stub runner for Cat (REST) Service in context:

```editor:select-matching-text
file: ~/cat-client/src/test/java/com/example/catclient/CatClientApplicationTests.java
text: "@AutoConfigureStubRunner"
after: 3
```

First, we configure the `ids` property which is in `ivy notation`—per the doc—`" ([groupId]:artifactId[:version][:classifier][:port]). groupId, version, classifier and port can be optional."`. The [docs](https://cloud.spring.io/spring-cloud-contract/reference/html/project-features.html#features-stub-runner-downloading-stub) suggest we have multiple options to find a stub, and in this Cat test we use `local` since our artifact (the sub built by verifier in that last step) will end up in the `.m2` directory.

***By default, Spring Cloud Contract integrates with Wiremock as the HTTP server stub.***

Next, we can write the test as usual.
Remember the stub runner locates and executes our Stub, which is really a [WireMock](http://wiremock.org/) service that models our service; its not the real service, just a static stub of it.
The test simply calls the Cat REST endpoint (the stub) and evaluates that the result is consistent with client's expectations.

Click here to see the cat-client in context:

```editor:select-matching-text
file: ~/cat-client/src/test/java/com/example/catclient/CatClientApplicationTests.java
text: "@SpringBootTest"
after: 12
```

Because this is a `@SpringBootTest`, all client dependencies will be configured as a full application, thus the stub-runner facilitates the server-side (in this case our Wiremock stub).

With the client out of the way, we have come to the conclusion of our local-bound test section. Given the success of these tests, we can be confident the cats will always land on their 4 legs! This bring us to the automated-testing and build phases in the next section.