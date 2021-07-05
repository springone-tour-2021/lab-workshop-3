## Build the container image

In the previous exercises you walked through the testing that happens during a `maven package` of the cat-service application.
At the end of this operation, you have a tested Java .jar file.

However, in order to deploy this application to Kubernetes, you need package the application as a container image, not a .jar file.
A container image is a deployment artifact that is compatible with container runtime systems such Docker and Kubernetes, and which contains not only the application but also the runtime (JRE) and OS file system.

Spring Boot includes native support for generating images via the Spring Boot [maven](https://docs.spring.io/spring-boot/docs/current/maven-plugin/reference/htmlsingle/#build-image) and [gradle](https://docs.spring.io/spring-boot/docs/current/gradle-plugin/reference/htmlsingle/#build-image) build plugins.

Generate an image for cat-service.
You can skip tests since you already verified that tests pass in the previous exercises.
```execute-1
./mvnw spring-boot:build-image -DskipTests
```

Scroll through the output in the console until you find the following line.
We won't go into the meaning of this line now, but make a mental note of it.
We will come back to it in a later exercise.
```
[INFO]  > Pulling builder image 'docker.io/paketobuildpacks/builder:base' 100%
```

Check for the resulting image on the local Docker daemon.
```execute-1
docker images | grep cat-service
```

Tag and push the image to the Docker registry provided for this tutorial.
```execute-1
docker tag cat-service:0.0.1-SNAPSHOT $REGISTRY_HOST/cat-service
docker push $REGISTRY_HOST/cat-service
```

Use the [skopeo CLI](https://github.com/containers/skopeo) to verify that the image has been pushed to the repository.
```execute-1
skopeo list-tags docker://$REGISTRY_HOST/cat-service
```