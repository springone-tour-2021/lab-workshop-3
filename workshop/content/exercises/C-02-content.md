## Deploy manually to Kubernetes

### Imperative vs Declarative

Applications can be deployed to Kubernetes _imperatively_ or _declaratively_.
- Imperative:
    - Using a CLI and command-line options operating on running resources (e.g. `kubectl run...`, `kubectl scale ...`, `kubectl set env ...`)
    - CLI commands describe how to arrive at a desired state
    - Configuration options are limited to those exposed through the CLI
- Declarative:
    - Using configuration _manifest_ files (typically in YAML syntax) that describe the desired deployment (e.g. `kubectl apply my-app.yaml`)
    - Manifests express - or declare, as it were - the desired state, serving as a blueprint and "source of truth" for a running system
    - Manifests make it possible to configure any aspect of a given resource

The declarative approach follows the methodology of "infrastructure as code" and enables [GitOps](https://www.gitops.tech) as a methoology for managing deployments. It is the approach you will use here.

### Review deployment manifests

To deploy the application to Kubernetes, you need:
1. Manifests describing the deployment of the postgres database
2. Manifests describing the deployment of the cat-service application

For this workshop, the necessary manifests are provided in a separate `ops` repository.

Navigate into the `cat-service-release-ops` repo that you cloned & forked earlier.
```execute-all
cd ~/cat-service-release-ops
```

List the files in this directory.
The files are organized into two main directories, `base` and `overlays`.
The files in `base` describe the basic application deployment.
The files in `overlays` describe environment-specific configuration changes.
```execute-1
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
These enable the use of [kustomize](https://kustomize.io), a tool for composing and customizing yaml configuration.

Let's focus on the `manifests/base/app` directory.
- This directory contains the typical deployment and service manifests.
The deployment resource will deploy and manage the pod in which the application will run, and the service will make the application accessible outside the cluster.
- You can also see the application's properties file.
This file will be converted into a ConfigMap that the app can read from at startup.
- The kustomization.yaml file ties it all together. It tells kustomize which files to use and what further modifications to make so that kustomize can produce the yaml you want to apply.

Take a look at the `kustomization.yaml` file.
```editor:open-file
file: ~/cat-service-release-ops/manifests/base/app/kustomization.yaml
```

To see this in action, use the `kustomize` CLI to generate the final yaml.
> Note: This command just produces yaml; it does not apply it to the cluster.
```execute-1
kustomize build --load-restrictor=LoadRestrictionsNone manifests/base/app/
```

Compare the output to the contents of the source files. Notice that a ConfigMap was generated from the properties file, and the image tag was replaced with `latest`.

### What about the database?

There are different strategies for managing the deployment of the database.
For simplicity, we have included the postgres manifests together with the app manifests.
The postgres deployment is described in the file `manifests/base/db/postgres.yaml`.
Feel free to look through that file, though that will not be an area of focus in this workshop.
The only thing worth noting is that the `manifests/base` directory contains a `kustomization.yaml` file that combines the resources in `manifests/base/app` and `manifests/base/db`, so the database deployment will be included in the base deployment. You can view the `manifests/base/db/*` and `manifests/base/kustomization.yaml` files in the Editor if you wish to examine this in more detail.

### Deployment requirements

The manifest generated from the `manifests/base/app` configuration would deploy resources to the default namespace. The DevOps team has specified that you should use namespaces called dev and prod.

In addition, the DevOps team has requested that resource names be prefixed with "dev" and "prod", as appropriate.

You can use kustomize to meet both requirements.

#### Deploy to dev

Examine the dev kustomization configuration.
```editor:open-file
file: ~/cat-service-release-ops/manifests/overlays/dev/kustomization.yaml
```

Preview the yaml that will be generated using the dev overlay.
```execute-1
kustomize build --load-restrictor=LoadRestrictionsNone manifests/overlays/dev/
```

In this case, you should see three key differences:
1. All resource names are prefixed with "dev"
2. All resources specify the namespace "dev"
3. The overlay includes the database manifest

Deploy the application to the dev environment:
```execute-1
kustomize build --load-restrictor=LoadRestrictionsNone manifests/overlays/dev/ | kubectl apply -f -
```

Wait until the dev-cat-service pod is "Running" and the Ready column specifies "1/1".
> Note: the database must complete startup before the app can start successfully, so you will likely see the app restart a few times before it finaly succeeds.
```execute-1
kubectl -n $SESSION_NAMESPACE-dev get pods --watch
```

When the cat-service pod is ready (STATUS=Running and READY=1/1), stop the watch process.
```execute-1
<ctrl-c>
```

#### Test the dev deployment

In terminal 2, start a port-forwarding process so that you can send a request to the running application.
```execute-2
kubectl port-forward service/dev-cat-service 8080:8080 -n $SESSION_NAMESPACE-dev
```

Send a couple of requests to the application.
You should see successful responses.
```execute-1
http :8080/actuator/health
```

```execute-1
http :8080/cats/Toby
```

Stop the port-forwarding process.
```execute-2
<ctrl-c>
```

#### Cleanup

To delete the dev deployment, run:
```execute-1
kustomize build --load-restrictor=LoadRestrictionsNone manifests/overlays/dev/ | kubectl delete -f -
```

#### Deploy to prod

Optionally, you can repeat the steps in this exercise, using the prod namespace and overlay.

## Next Steps
In the next steps, you will automate the test, build, and deployment of the application.
