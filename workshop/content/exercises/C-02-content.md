Now that you've got an image, you're ready to deploy it to Kubernetes.

Let's do this manually first.

## Imperative vs Declarative

Applications can be deployed to Kubernetes _imperatively_ or _declaratively_.
- Imperative:
    - Using a CLI and command-line options operating on running resources (e.g. `kubectl run...`, `kubectl scale ...`, `kubectl set env ...`)
    - CLI commands describe how to arrive at a desired state
    - Configuration options are limited to those exposed through the CLI
- Declarative:
    - Using configuration _manifest_ files (typically in YAML syntax) that describe the desired deployment (e.g. `kubectl apply my-app.yaml`)
    - Manifests express—or declare—the desired state, serving as a blueprint and "source of truth" for a running system
    - Manifests make it possible to configure any aspect of a given resource

The declarative approach aligns with the idea of "infrastructure as code" and enables [GitOps](https://www.gitops.tech) as a methodology for managing deployments. It is the approach you will use here.

To deploy _Cat Service_ application to Kubernetes, you need:
1. Manifests describing the deployment of the postgres database
2. Manifests describing the deployment of the cat-service application

## Review deployment manifests

The `cat-service-release-ops` repo contains the manifests you need.
List the files in this directory.
The files are organized as `base` and `overlays`.
- The base files describe the basic application deployment
- The overlay files describe environment-specific configuration changes

```execute-1
cd ~/cat-service-release-ops
tree manifests
```

Your output will show:
```
manifests/
├── base
│         ├── app
│         │         ├── application.properties
│         │         ├── deployment.yaml
│         │         ├── kustomization.yaml
│         │         └── service.yaml
│         ├── db
│         │         ├── kustomization.yaml
│         │         └── postgres.yaml
│         └── kustomization.yaml
└── overlays
    ├── dev
    │         └── kustomization.yaml
    └── prod
        ├── kustomization.yaml
        └── patch-env.yaml
```

Notice that each directory contains a file called `kustomization.yaml`.
These files enable the use of [kustomize](https://kustomize.io), a tool for composing and customizing yaml configuration.

Let's focus on the `manifests/base/app` directory.
This directory contains:
- the typical deployment and service manifests (the deployment resource creates and manages the pod in which an application runs; the service provides an endpoint for requests to an app)
- the Java application's properties file, to be converted into a ConfigMap for the app
- a kustomization.yaml file that ties it all together - it specifies which files to use and what modifications to make

Take a look at the `kustomization.yaml` file.
```editor:append-lines-to-file
file: ~/cat-service-release-ops/manifests/base/app/kustomization.yaml
text: |
    apiVersion: kustomize.config.k8s.io/v1beta1
    kind: Kustomization

    resources:
    - deployment.yaml
    - service.yaml

    configMapGenerator:
    - name: cat-service-config
      files:
      - application.properties

    images:
    - name: gcr.io/pgtm-jlong/cat-service # used for Kustomize matching
      newTag: latest
      newName: {{registry_host}}/cat-service
```

Notice anything odd? This kustomization will rename your cat-service image to `MY_REGISTRY/cat-service`. 
Kubernetes will try to pull an image with this name, but this won't work. 
There is no such image. 
You need to update this value using your workshop session's registry adress.

To get this value, run the following command:
```execute-1
echo $REGISTRY_HOST
```

Copy this value and paste it into the editor. 
The result should look something like this (your value will be different).
```
images:
  - name: gcr.io/pgtm-jlong/cat-service # used for Kustomize matching
    newTag: latest
    newName: eduk8s-labs-w14-s005-registry.s1tour-a2edc10.tanzu-labs.esp.vmware.com/cat-service
```

Make sure you only changed `newName` and not `name`. Kustomize will find references based on the name and update them to the new value.

The kustomization file also includes instructions to convert the application.properties file into a ConfigMap.

To see this in action, use the `kustomize` CLI to preview the final yaml.
> Note: This command just produces yaml; it does not apply it to the cluster.
```execute-1
kustomize build manifests/base/app/
```

Compare the output to the contents of the source files. Notice that a ConfigMap was generated from the properties file, and the image name and tag were updated..

## What about the database?

There are different strategies for managing the deployment of the database.
For simplicity, we have included the postgres manifests in the same base kustomization.
Feel free to examine the files in `manifests/base/db/*` as well as `manifests/base/kustomization.yaml`.
However, this will not be an area of focus in this tutorial.

## Deploy to dev

Examine the `dev` kustomization configuration.
```editor:open-file
file: ~/cat-service-release-ops/manifests/overlays/dev/kustomization.yaml
```

Preview the yaml that will be generated.
```execute-1
kustomize build manifests/overlays/dev/
```

You should see these key differences:
1. All resource names (`metadata.name`) are prefixed with "dev"
2. The overlay result includes the database manifests

Pipe the output to kubectl to deploy to Kubernetes.
```execute-1
kustomize build manifests/overlays/dev/ | kubectl apply -f -
```

You can watch the progress of the deployment.
> Note: the database must complete startup before the app can start successfully, so you will likely see the app restart a few times before it finally succeeds.
```execute-1
kubectl get pods --watch
```

When the cat-service pod is ready (STATUS=Running and READY=1/1), stop the watch process.
```execute-1
<ctrl-c>
```

### Test the dev deployment

In terminal 2, start a port-forwarding process so that you can send requests to the running application.
```execute-2
kubectl port-forward service/dev-cat-service 8080:8080
```

Send a request to Spring Boot actuator to check the health of the app.
```execute-1
http :8080/actuator/health
```

Send a request for Toby the cat.
```execute-1
http :8080/cats/Toby
```

Stop the port-forwarding process.
```execute-2
<ctrl-c>
```

## Cleanup

Delete the dev deployment.
```execute-1
kustomize build manifests/overlays/dev/ | kubectl delete -f -
```

## Deploy to prod

As an exercise, you can repeat these steps using the prod overlay.
