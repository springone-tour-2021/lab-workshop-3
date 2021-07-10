Now that the code is tested, you can start the process of deploying to Kubernetes.

First order of business is to package it as a container image.

A container image is a deployment artifact that is compatible with container runtime systems such Docker and Kubernetes, and which contains not only the application but also the runtime (JRE) and OS file system.

## Build the image

The Spring Boot [maven](https://docs.spring.io/spring-boot/docs/current/maven-plugin/reference/htmlsingle/#build-image) and [gradle](https://docs.spring.io/spring-boot/docs/current/gradle-plugin/reference/htmlsingle/#build-image) build plugins make it easy to build images. 
Run the following command to generate an image for cat-service.
```execute-1
cd ~/cat-service
./mvnw spring-boot:build-image -DskipTests
```

_As an aside... notice the following line in the build output.
[Paketo Buildpacks](https://paketo.io) are doing the hard work of turning your app into an image.
Make a mental note of this.
We will come back to it later in the workshop._
```
[INFO]  > Pulling builder image 'docker.io/paketobuildpacks/builder:base' 100%
```

Check for the resulting image on the local Docker daemon.
```execute-1
docker images | grep cat-service
```

## Push the image

In order to depoy it to Kubernetes, you must push the image to an image registry so Kubernetes can access. A registry is included in your tutorial environment.

Tag the image with the registry address and push it to the registry.
```execute-1
docker tag cat-service:0.0.1-SNAPSHOT $REGISTRY_HOST/cat-service
docker push $REGISTRY_HOST/cat-service
```

You can use the [skopeo CLI](https://github.com/containers/skopeo) to verify that the image has been pushed to the registry.
```execute-1
skopeo list-tags docker://$REGISTRY_HOST/cat-service
```
