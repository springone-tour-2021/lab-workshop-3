## Build the container image

Now that the code is tested, you can start the process of deploying to Kubernetes.

First order of business is to package it as a container image.

A container image is a deployment artifact that is compatible with container runtime systems such Docker and Kubernetes, and which contains not only the application but also the runtime (JRE) and OS file system.

Spring Boot includes native support for generating images via the Spring Boot [maven](https://docs.spring.io/spring-boot/docs/current/maven-plugin/reference/htmlsingle/#build-image) and [gradle](https://docs.spring.io/spring-boot/docs/current/gradle-plugin/reference/htmlsingle/#build-image) build plugins.

Generate an image for cat-service.
You can skip tests since you already verified the code.
```execute-1
cd ~/cat-service
./mvnw spring-boot:build-image -DskipTests
```

Notice the following line in the output in the console.
[Paketo Buildpacks](https://paketo.io) are doing the hard work of turning your app into an image.
Make a mental note of this.
We will come back to it later in the workshop.
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

Use the [skopeo CLI](https://github.com/containers/skopeo) to verify that the image has been pushed to the registry.
```execute-1
skopeo list-tags docker://$REGISTRY_HOST/cat-service
```