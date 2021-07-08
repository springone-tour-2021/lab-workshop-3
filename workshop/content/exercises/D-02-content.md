## Automate building

Earlier in this workshop you built a container image manually using `mvn spring-boot:build-image`.
Under the covers, Spring Boot is using a technology called [Cloud Native Buildpacks](https://buildpacks.io/). The maven plugin is very handy for certain workflows, such as building an image on your local machine, or including it in a shell script executed by an automation toolchain like Github Actions, Jenkins, and so on.

However, there is alternate tool that also uses Cloud Native Buildpacks (meaning it can generate the same image as the Spring Boot plugin) and provides a more robust set of features for building images at scale. This tool is called [kpack](https://github.com/pivotal/kpack). This is the tool you will use now to automate building a container image for cat-service each time there is a new version of code that has passed testing.

kpack runs on Kubernetes. In this exercise, you will use kpack it to monitor the cat-service-release repo and push images to the tutorial Docker registry whenever there is a new commit.

### Review kpack installation

This tutorial environment hosts many user sessions in the same Kubernetes cluster, and there can only be one installation of kpack per cluster.
Therefore, kpack has already been installed.
If you are interested in installation instructions, read [this](https://github.com/pivotal/kpack/blob/main/docs/install.md).

List the Custom Resource Definitions (CRDs) that kpack has added to your cluster.
```execute-1
kubectl api-resources | grep kpack
```

In the next steps, you will create a builder and an image to automate builds for `cat-service-release`.

### Review kpack configuration

Cloud Native Buildpacks require you to specify a "builder". 
A builder is an image that provides the base image and the logic to build your application image.

Recall the mental note you made during `mvn spring-boot:build-image` earlier.
The build-image logs showed the builder that Spring Boot uses [Paketo Buildpacks](https://paketo.io) by default:
```
[INFO]  > Pulling builder image 'docker.io/paketobuildpacks/builder:base' 100%
```

kpack cannot directly access the same builder image; it must assemble its own.
However, you can configure kpack to assemble a builder image using the same building blocks as the Paketo builder.
This way you guarantee that images built using the Spring Boot plugin and images built by kpack are built in the same way.

The building blocks of builders are stacks (OS file system) and stores (buildpacks).
Notice in the list of _kpack api-resources_ that stacks and stores are cluster-scoped only, while builders can be namespaced.
Because of this, the stack and the store have also been created already.
```execute-1
kubectl get clusterstacks,clusterstores
```

You can examine the configuration that was applied to create these resources.
Notice that they take advantage of the existing Paketo Buildpacks images.
```editor:open-file
file: ~/cat-service-release-ops/tooling/kpack-config/stack.yaml
```
```editor:open-file
file: ~/cat-service-release-ops/tooling/kpack-config/store.yaml
```

### Create a builder

Given a clusterstack and a clusterstore, you can create a builder. Once you have a builder, you can create an image resource for `cat-service-release`.

Notice in the list of api-resources there are two kinds of builder:
- clusterbuilders
- builders

Clusterbuilders can be used by image resources across the cluster, and namespaced builders can only be used by image resources in the same namespace.

In this step, you will create a namespaced builder.

Examine the manifest for the builder.
Notice the tag.
kpack will assemble a builder image and publish it using the information specified in the `tag`.
> Note: Notice also the serviceAccount is set to "default."
> In your workshop session, this service account has already been granted write access to publish images to the container registry specified in the tag.
 ```editor:select-matching-text
file: ~/cat-service-release-ops/tooling/kpack-config/builder.yaml
text: tag:
```

Apply the builder manifest to instruct kpack to create the builder.
```execute-1
kubectl apply -f ~/cat-service-release-ops/tooling/kpack-config/builder.yaml
```

Wait for builder to be ready
```execute-1
kubectl get bldr booternetes-builder -w
```

When the output shows a reference to a builder, run the following command to verify the new builder image is in the Docker registry.
```execute-1
skopeo list-tags docker://$REGISTRY_HOST/booternetes-builder
```

This builder can now be used by anyone with access to the registry - presumably everyone in the organization. You can now ensure that all apps across the org are built using the same components (base image, Java runtime, etc), and incorporate the same additional features the buildpacks provide (e.g. Paketo Java memory calculator, clean exits on out-of-memory errors, and more).

### Configure kpack for cat-service

Next, you need to tell kpack to build the cat-service application using this builder, and to put the resulting app image in the Docker registry.

Review the image definition.
Notice that you are instructing kpack to poll the cat-service-release repository on GitHub for any new commits on the release branch.
```editor:open-file
file: ~/cat-service-release-ops/build/kpack-image.yaml
```

Apply the image manifest.
```execute-1
kubectl apply ~/cat-service-release-ops/build/kpack-image.yaml
```

You should immediately see a build resource for the first build of cat-service-release, as well as a pod, which is where the actual assembly of the image will be carried out.
Check for both builds and pods.
```execute-1
kubectl get builds,pods
```

Wait until the build returns `SUCCEEDED=True`.
At that point you will also see the image reference in the output.
```execute-1
kubectl get builds -w
```

At this point, you can also check the Docker registry to confirm that the app image has been published.
Notice the tag naming convention that kpack uses by default.
```execute-1
skopeo list-tags docker://$REGISTRY_HOST/cat-service
```

kpack will poll the source code repo and the builder image every 5 minutes, and will automatically rebuild - or rebase, as approrpriate - if it detects a change.

## Next Steps

In the next exercises, you will automate the deployment of this image to Kubernetes.


---
---
---
---
> TODO: decide whether or not to use anything from below...
## Behind the scenes

For convenience, store the build name and number of the latest build in env vars.
```
LATEST_BUILD=$(kubectl get builds -o yaml | yq r - "items[-1].metadata.name") \
&& echo "Latest build: ${LATEST_BUILD}"
BUILD_NR=$(kubectl get builds -o yaml | yq r - "items[-1].metadata.labels.[image.build.pivotal.io/buildNumber]")
echo "LATEST_BUILD=${LATEST_BUILD}"
echo "BUILD_NR=${BUILD_NR}"
```{{execute}}

You can use `kubectl describe` to get more information about the build.

```
kubectl describe build ${LATEST_BUILD}
```{{execute}}

Notice that the build description includes such details as the source commit id and the reson for the build:
```
kubectl describe build ${LATEST_BUILD} | grep Revision
kubectl describe build ${LATEST_BUILD} | grep reason | head -1
```{{execute}}

The Build creates a Pod in order to execute the build and produce the image.

```
kubectl get pods | grep ${LATEST_BUILD}
```{{execute}}

You should see evidence of _init_ containers in the results (something like: "Init:1/6"). kpack orchestrates the CNB lifecycle using _init_ containers - a prepare container, plus containers for each lifecycle step: detect, analyze, restore, build, export. (These should sound familiar based on the logs that `pack` generated in the last step). A simple `kubectl logs` command will not stream the init container logs, so kpack provides a `logs` CLI to make it easy to extract the logs from all init containers:

```
logs -image go-sample-app -build ${BUILD_NR}
```{{execute}}

You should see logging similar to the logging you saw with `pack`, since the underlying process using the Paketo Builder is the same.

When the log shows that the build is done, check your [Docker Hub](https://hub.docker.com) to validate that an image has been published. The image will have a tag as specified in your Image configuration, as well as an auto-generated tag. Both tags are aliasing the same image digest.

## Trigger a new build

By default, kpack will poll the source code repo, the builder image, and the run image every 5 minutes, and will automatically rebuild - or rebase, as approrpriate - if it detects a new commit.

Notice that the Image resource is configured to poll the master branch on the app repo. That means any commit to the master branch will trigger a build.






