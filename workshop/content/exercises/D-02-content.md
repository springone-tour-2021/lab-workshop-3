## Automate building

As you can see, it's quite easy to build a container image using `mvn spring-boot:build-image`.
Under the covers, Spring Boot employs a technology called [Cloud Native Buildpacks](https://buildpacks.io). 

The maven plugin is very handy for certain workflows, such as building an image on your local machine, or in an automation toolchain like Github Actions, Jenkins, and so on.

However, there is another tool that also employs Cloud Native Buildpacks and provides a more robust set of features for building images at scale. 
This tool is called [kpack](https://github.com/pivotal/kpack). 

In this exercise, you will use kpack so that a new image is built automatically each time there is a new commit to the `cat-service-release` repo.

### Review kpack installation

kpack has already been installed into the workshop cluster.
> Interested in the installation instructions? Read [this](https://github.com/pivotal/kpack/blob/main/docs/install.md).

List the Custom Resource Definitions (CRDs) that kpack has added to your cluster.
```execute-1
kubectl api-resources | grep kpack
```

In the next steps, you will create a "builder" and an "image" to automate builds for `cat-service-release`.

### Create a builder

Recall the mental note you made during `mvn spring-boot:build-image`.
The build-image logs showed the precise builder that Spring Boot uses by default:
```
[INFO]  > Pulling builder image 'docker.io/paketobuildpacks/builder:base' 100%
```

kpack cannot directly access the same builder; it must assemble one on its own.
However, you can configure kpack to assemble a builder image using the same building blocks as the Paketo builder.
This way you guarantee that images built using the Spring Boot plugin and images built by kpack are built in the same way.

The building blocks of builders are stacks (OS file system) and stores (buildpacks).
Notice in the list of _kpack api-resources_ that stacks and stores are cluster-scoped only, while builders can be namespaced.
Because of this, the stack and the store have already been created in the workshop environment.

List the existing stack and store.
```execute-1
kubectl get clusterstacks,clusterstores | grep $WORKSHOP_NAMESPACE
```

Examine the configuration that was applied to create these resources.
Notice that they reuse building blocks of Paketo Buildpacks rather than defining a stack and store from scratch.

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

You are now ready to create a builder.

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

Apply the builder manifest to instruct kpack to create the builder.
```execute-1
kubectl apply -f ~/cat-service-release-ops/kpack/builder.yaml
```

Wait for builder to be ready.
```execute-1
kubectl get bldr booternetes-builder -w
```

When the output shows a reference to a builder, run the following command to verify the new builder image is in the Docker registry.
```execute-1
<ctrl-c>
```
```execute-1
skopeo list-tags docker://$REGISTRY_HOST/booternetes-builder
```

This builder can now be used by anyone with access to the registry - presumably everyone in the organization. You can now ensure that all apps across the org are built using the same components (base image, Java runtime, etc), and incorporate the same additional features the buildpacks provide (e.g. Paketo Java memory calculator, clean exits on out-of-memory errors, and more).

### Configure kpack for cat-service

Next, you need to tell kpack to build the cat-service image.

Click on the action block to create the image manifest.
Review its contents and notice that you are instructing kpack to poll the cat-service-release repository for any new commits on the release branch.
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

Notice also that the image resource will use a service account.
```editor:select-matching-text
file: ~/cat-service-release-ops/kpack/image.yaml
text: 'serviceAccount: kpack-builder'
```

You need to create the service account, as well as a secret with credentials for pushing to the registry.
Create the service account and secret manifests.
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
logs -image cat-service -build 1 -namespace ${SESSION_NAMESPACE}
```

You can also watch the status of the build.
When it is ready, you will see `SUCCEEDED=True` and a reference to the published image.
```execute-1
kubectl get builds -w
```

At this point, you can also check the Docker registry to confirm that the app image has been published.
Notice that kpack applies two tags - a build tag and "latest."
```execute-1
skopeo list-tags docker://$REGISTRY_HOST/cat-service
```

kpack will poll the source code repo and the builder image every 5 minutes and will update the image if either changes.

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






