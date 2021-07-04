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

> TODO: Change to `git clone -b 1.0`

Clone the ops repo:
```execute-1
cd ~
git clone https://github.com/booternetes-III-springonetour-july-2021/cat-service-release-ops.git
```

Navigate into the cloned repo.
```execute-1
cd ~/cat-service-release-ops
```

List the files in this directory
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

Notice that the files are organized into two main directories, `base` and `overlays`.
The files in `base` describe the basic application deployment.
The files in `overlays` describe environment-specific configuration changes for the dev and prod environments.

You can see that each directory contains a file called `kustomization.yaml`.
These enable the use of [kustomize](https://kustomize.io), a tool for composing an customizing yaml configuration. It is available as a standalone executable called `kustomize`, and it is also integrated with `kubectl apply` using the `-k` flag.

For clarity and simplicity, start by focusing only on the `manifests/base/app` directory.
```execute-all
ls -l manifests/base/app
```

The deployment and service yaml files are the typical manifests for app deployments.
The deployment resource will deploy and manage the pod in which the application will run, and the service will make the application accessible outside the cluster.

In addition, you can see the application.properties file from the app repo has been copied here.
It is good practice to externalize configuration from the application, so that the configuration can be changed for different environments or updated ithout rebuilding the application.
Kubernetes provides a way to make that configuration available to the running application via a ConfigMap.
In order to deploy this application to Kubernetes, you need to convert the `application.properties` file to a ConfigMap, and then use `kubectl` to apply the resulitng ConfigMap manifest, the deployment manifest, and the service manifest. Luckily, `kustomize` can automatically do all of these things for you.

Take a look at the file `kustomization.yaml`.
```execute-1
cat manifests/base/app/kustomization.yaml
```

Your output will look like this:
```yaml
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
```

Notice that kustomize will include the two basic resource files, deployment and service, and generate a ConfigMap from the application.properties file. It will also overwrite the image tag in `deployment.yaml` with `latest`, which matches the tag you used when you pushed the cat-service image to the Docker repository in the previous exercise.

To see this in action, use `kubectl apply` with the `-k` flag, which provides native support for kustomize.
Also, use the `--dry-run` flag so that the resulting yaml is not applied to Kubernetes.
You will be doing that shortly.
```execute-1
kubectl apply -k manifests/base/app --dry-run=client -o yaml
```

Examine the output of the last command and compare it to the contents of the source files. You can use the `cat` command in terminal 2 to vie wthe output of the source resources, or you can view the files in the Editor (click on the `Editor` tab).

### What about the database?

There are different strategies for managing the deployment of the database.
For simplicity, we have included the postgres manifests together with the app manifests.
The postgres deployment is described in the file `manifests/base/db/postgres.yaml`.
Feel free to look through that file, though that will not be an area of focus in this workshop.
The only thing worth noting is that the `manifests/base` directory contains a `kustomization.yaml` file that combines the resources in `manifests/base/app` and `manifests/base/db`, so the database deployment will be included in the base deployment. You can view the `manifests/base/db/*` and `manifests/base/kustomization.yaml` files in the Editor if you wish to examine this in more detail.

### Deploy manually

The manifest generated from the `manifests/base/app` configuration would deploy resources to the default namespace. The DevOps team has specified that you should use namespaces called dev and prod.

In addition, the DevOps team has requested that resource names be prefixed with "dev" and "prod", as appropriate.

You can use kustomize to meet both requirements.

#### Deploy to dev

Examine the contents of the `manifests/overlays/dev/kustomization.yaml` file.
```execute-1
cat manifests/overlays/dev/kustomization.yaml
```

Your output will show:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - ../../base/

namespace: dev
namePrefix: dev-
```

In terminal 2, preview the yaml that will be generated using the dev overlay.
```execute-2
kubectl apply -k manifests/overlays/dev --dry-run=client -o yaml
```

Compare the output to the output generated by the base/app manifests in terminal , earlier in this exercise.
You should see three key differences:
1. All resource names in the overlay deployment are prefixed with "dev"
2. All resources in the overlay deployment  specify the namespace "dev"
3. The overlay deployment includes the postgres resources

Deploy the application to the dev environment:
```execute-1
kubectl create namepace dev
kubectl apply -k manifests/overlays/dev
```

Watch the pods until the dev-cat.
Wait until the dev-cat-service pod is "Running" and the Ready coulmn specifies "1/1".
> Note: the dev-cat-service pod may need to restart a few times.
> This is because it fails when it cannot connect to the database, and since we are deploying both at the same time this first time, the app needs to wait until the database is ready before it can successfully start up.
```execute-1
kubectl -n dev get pods --watch
```

#### Test the dev deployment

In terminal 2, start a port-forwarding process so that you can send a request to the running application.
```execute-2
kubectl port-forward service/dev-cat-service 8080:8080 -n dev
```

In terminal 1, send a couple of requests to the application.
```execute-1
http :8080/actuator/health
```

```execute-1
http :8080/cats/Toby
```

Stop the port-forwarding process.
```execute-2
Ctrl-C
```

#### Cleanup

To delete the dev deployment, run:
```execute-1
kubectl delete -k manifests/overlays/dev
kubectl delete namepace dev
```

#### Deploy to prod

Optionally, you can repeat the steps in this exercise, using the prod namespace and the prod overlay.

## Next Steps
In the enxt steps, you will automate the test, build, and deployment of the application.