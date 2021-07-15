As you can see, it's very easy to build a container image using `mvn spring-boot:build-image`.

Who is doing all the hard work?

Under the covers, Spring Boot employs a technology called [Cloud Native Buildpacks](https://buildpacks.io) (CNB). 
CNB provides a structured way to assemble container images for applications. CNB is all about "how to build an image."

Remember that line from the build log?
```
[INFO]  > Pulling builder image 'docker.io/paketobuildpacks/builder:base' 100%
```

Spring Boot is specifically employing [Paketo Buildpacks](https://paketo.io) to apply the more detailed know-how for specific languages, Java included, of course. 
Paketo Buildpacks are part of the CNB ecosystem. 
Buildpacks are all about "what to do with specific app files."

In any case, the maven plugin is very handy for certain workflows, such as building an image on your local machine, or in an automation toolchain like Github Actions, Jenkins, and so on.

However, there is another tool that also employs Cloud Native Buildpacks and provides a more robust set of features for building images at scale. 
This tool is called [kpack](https://github.com/pivotal/kpack). 

In this exercise, you will use `kpack` so that a new image is built automatically each time there is a new commit to the `cat-service-release` repo.

## Review kpack installation

kpack has already been installed into the workshop cluster.

_Interested in the installation instructions? Read [this](https://github.com/pivotal/kpack/blob/main/docs/install.md)._

List the Custom Resource Definitions (CRDs) that kpack has added to your cluster.
```execute-1
kubectl api-resources | grep kpack
```

In the next steps, you will create a "Builder" and an "Image" to automate builds for `cat-service-release`.

## Create a builder

In contrast to `spring-boot:build-image`, kpack cannot directly access the publicly available Paketo Buildbacks builder image (`docker.io/paketobuildpacks/builder:base`). By design, kpack must assemble its own builder.

However, you can configure kpack to assemble a builder by re-using elements of the Paketo builder.
This way you guarantee that app images built by Spring Boot and app images built by kpack are built in the same way.


### Examine the configuration

The building blocks of builders are stacks (OS file system) and stores (buildpacks).
Notice in the list of _kpack api-resources_ that stacks and stores are cluster-scoped only, while builders can be namespaced.
Because of this, the stack and the store have already been created in the workshop environment.

List the existing stack and store.
```execute-1
kubectl get clusterstacks,clusterstores | grep $WORKSHOP_NAMESPACE
```

Examine the configuration that was applied to create these resources.
Notice how they reuse the Paketo build and run images, and they reuse the store (aka the language-specific buildpacks).

The stack:
```
apiVersion: kpack.io/v1alpha1
kind: ClusterStack
metadata:
  name: {{workshop_namespace}}-stack
spec:
  id: "io.buildpacks.stacks.bionic"
  buildImage:
    image: "paketobuildpacks/build:base-cnb"
  runImage:
    image: "paketobuildpacks/run:base-cnb"
```

The store:
```
apiVersion: kpack.io/v1alpha1
kind: ClusterStore
metadata:
  name: {{workshop_namespace}}-store
spec:
  sources:
    - image: paketobuildpacks/builder:base
```

You are now ready to configure the builder.

Create a directory for kpack manifests.
```execute-1
mkdir ~/cat-service-release-ops/kpack
```

Create the builder manifest.
```editor:append-lines-to-file
file: ~/cat-service-release-ops/kpack/builder.yaml
text: |
    apiVersion: kpack.io/v1alpha1
    kind: Builder
    metadata:
      name: booternetes-builder
    spec:
      tag: {{registry_host}}/booternetes-builder
      serviceAccount: default
      stack:
        name: {{workshop_namespace}}-stack
        kind: ClusterStack
      store:
        name: {{workshop_namespace}}-store
        kind: ClusterStore
      order:
        - group:
            - id: paketo-buildpacks/java
        - group:
            - id: paketo-buildpacks/nodejs
```

Examine the manifest for the builder.
Notice the tag and the service account.
- The tag contains the address of the registry in the tutorial environment.
  kpack will assemble a builder image and publish it using this information.
- The service account has already been granted write permissions to the container registry.

```editor:select-matching-text
file: ~/cat-service-release-ops/kpack/builder.yaml
text: 'tag:'
after: 1
```

Notice also the `order` configuration.
Paketo Buildpacks can handle a handful of languages, but we are only including Java and Nodejs in this builder.

```editor:select-matching-text
file: ~/cat-service-release-ops/kpack/builder.yaml
text: 'order:'
after: 4
```

### Create the builder image

Apply the builder manifest to instruct kpack to create the builder.
```execute-1
kubectl apply -f ~/cat-service-release-ops/kpack/builder.yaml
```

Wait for builder to be ready.
```execute-1
kubectl get bldr booternetes-builder -w
```

While you wait for the builder image to be ready, you can run the following command in terminal 2.
This will show any status, as well as more detail about the bits and pieces of Paketo Buildpacks that are being used to create this builder.
```execute-2
kubectl describe builder booternetes-builder
```

When the command in terminal 1 shows a reference to a builder, stop the watch process.
```execute-1
<ctrl-c>
```

The reference that appeared in the output in terminal 1 means the image was published, but you can use the skopeo CLI to see the new builder image in the Docker registry.
```execute-1
skopeo list-tags docker://$REGISTRY_HOST/booternetes-builder
```

This builder can now be used by anyone with access to the registry—presumably everyone in a given organization. All apps across the org will be built using the same components (base image, Java runtime, etc), and incorporate the same features the buildpacks provide (e.g. Paketo Java memory calculator, clean exits on out-of-memory errors, and more).

## Build the Cat Service image

Next, you need to tell kpack to build Cat Service.
You do this by creating an image resource.

### Configure the image resource
Click on the action block to create the image manifest.
Notice the configuration instructing kpack to poll the `cat-service-release` repository for any new commits on the `release` branch.
```editor:append-lines-to-file
file: ~/cat-service-release-ops/kpack/image.yaml
text: |
    apiVersion: kpack.io/v1alpha1
    kind: Image
    metadata:
      name: cat-service
    spec:
      builder:
        name: booternetes-builder
        kind: Builder
      serviceAccount: kpack-builder
      # cacheSize: "1.5Gi" # Optional, if not set then the caching feature is disabled
      source:
        git:
          url: https://github.com/<YOUR_GITHUB_ORG_HERE>/cat-service-release.git
          revision: release
      tag: {{registry_host}}/cat-service
```

Make sure to replace the org placeholder with your GitHub org name.
```editor:select-matching-text
file: ~/cat-service-release-ops/kpack/image.yaml
text: '<YOUR_GITHUB_ORG_HERE>'
```

Notice also that the image resource requires a service account.
The service account needs access to pull the builder and push the app image.
```editor:select-matching-text
file: ~/cat-service-release-ops/kpack/image.yaml
text: 'serviceAccount: kpack-builder'
```

Create the manifest for the service account.
```editor:append-lines-to-file
file: ~/cat-service-release-ops/kpack/service-account.yaml
text: |
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: kpack-builder
    secrets:
    - name: registry-credentials
    imagePullSecrets:
    - name: eduk8s-registry-credentials
```

Create the manifest for the secret with proper registry access.
```editor:append-lines-to-file
file: ~/cat-service-release-ops/kpack/secret.yaml
text: |
    apiVersion: v1
    kind: Secret
    metadata:
      name: registry-credentials
      annotations:
        kpack.io/docker : {{registry_host}}
    type: kubernetes.io/basic-auth
    stringData:
      username: {{registry_username}}
      password: {{registry_password}}
```

### Build the application image

Apply the manifests you just created.
```execute-1
kubectl apply -f ~/cat-service-release-ops/kpack/
```

You should immediately see a build resource for the first build of cat-service-release, as well as a pod, which is where the actual assembly of the image will be carried out.
Check for both builds and pods.
```execute-1
kubectl get builds,pods
```

You can use kpack's `logs` CLI to get the logs from a build.
The output should look similar to that of the `spring-boot:build-image` output.
```execute-1
logs -namespace ${SESSION_NAMESPACE} -image cat-service -build 1 
```

You can also watch the status of the build.
It will be "Unknown" while the build is in progress.
```execute-2
kubectl get builds -w
```

When the build is ready (`SUCCEEDED=True` and an image reference appears), stop the watch process.
```execute-2
<ctrl-c>
```

You can also check the Docker registry to confirm that the app image has been published.
> Notice that kpack applies two tags—a build tag and "latest." Make a mental note of the pattern of the build tag; you will use this later.
```execute-1
skopeo list-tags docker://$REGISTRY_HOST/cat-service
```

### Ongoing automation

kpack will poll the source code repo and the builder image every 5 minutes and will update the image if either changes.

If you like, you can commit another bump to the `cat-service` repo, wait for GitHub Actions to push the change to `cat-service-release`, and within 5 minutes you should see a second build resource in Kubernetes and a second image published to the image registry. You can re-run the last few commands in this exercise (`logs...` using build 2, `kubectl.... -w` to watch the build, and `skopeo` to check the registry).

## Next Steps

In the next exercises, you will deploy the Cat Service image to Kubernetes.
