## Automate image update deployments

Any update to the manifests will be detected by Argo CD.
However, we don't currently have an mechanism in place to update the manifests when a new app image is available.
This problem can be solved in different ways.
In this workshop, we are going to use a tool called [Argo CD Image Updater](https://argocd-image-updater.readthedocs.io/en/stable).

**How does it work?**

Argo CD Image Updater polls the container registry, and when it finds a new image, it updates the ops git repo.
To avoid conflict with manual updates, it writes to a separate file called .argocd-source-<app-name>.yaml (e.g. `manifests/overlays/dev/.argocd-source-dev-cat-service.yaml`).

The file contents might look something like this:
```yaml
kustomize:
  images:
  - my-registry.io/cat-service:b1.20210702.035806
```

At this point, Argo CD will detect the change to the ops repo and re-apply the manifests.

### Review Argo CD Image Updater installation

Argo CD Image Updater has already been installed into the workshop cluster.

_Interested in the installation instructions? Read [this](https://argocd-image-updater.readthedocs.io/en/stable/install/start/#installing-as-kubernetes-workload-in-argo-cd-namespace)._

Argo CD does not add any CRDs to the cluster.

### Additional configuration

#### Provide Argo Server API access to Image Updater

Argo CD Image Updater works in tandem with Argo CD.
It needs to talk to the argo-server API.

Hence, you need to create an account for Argo CD Image Updater in Argo CD with proper RBAC permissions and an API token.
You also need to provide the API token to Argo CD Image Updater via a Kubernetes secret.

Let's do this now.

Create a new account in Argo CD called "image-updater" and grant it the "apiKey" capability.
This capability allows generating authentication tokens for API access.
```execute-1
yq eval '.data."accounts.image-updater" = "apiKey"' \
     <(kubectl get cm argocd-cm -o yaml -n argocd) \
     | kubectl apply -f -
```

Create roles for new account.
You can add RBAC permissions to Argo CD's argocd-rbac-cm ConfigMap and Argo CD will pick them up automatically.

```execute-1
kubectl apply -n argocd -f tooling/argocd-image-updater-config/argocd-rbac-cm.yaml
```

Generate the API token.
You can do this using the `argocd` CLI.
```execute-1
alias argocd="argocd --port-forward --port-forward-namespace argocd"

argocd login --username admin --password $ARGOCD_PW

ARGOCD_API_TOKEN=$(argocd account generate-token \
                         --account image-updater \
                         --id image-updater)
```

Create a secret from the token generated above.
```execute-1
kubectl create secret generic argocd-image-updater-secret \
    --from-literal argocd.token=$ARGOCD_API_TOKEN \
    --dry-run=client -o yaml | kubectl apply -f - -n argocd
```

Restart the argocd-image-updater pod.
```execute-1
kubectl rollout restart deployment argocd-image-updater -n argocd
```

#### Provide GitHub write access to Image Updater

Argo CD Image Updater needs to push tag updates to the `cat-service-release-ops` repo when it detects new images.
This means you also need to provide a GitHub access token to Argo CD Image Updater via a Kubernetes secret.
You can use the token you set in the GITHUB_TOKEN environment variable earlier in the workshop.

Create a secret to enable Argo CD Image Updater to push to your GitHub ops repository.
```execute-1
kubectl create secret generic gitcred \
    --from-literal=username=$GITHUB_USER \
    --from-literal=password=$GITHUB_TOKEN \
    -n argocd
```

### Enable monitoring for the `cat-service` dev and prod applications

To enable Argo CD Image Updater to monitor a registry for new images, you need to configure the corresponding application resource with a particular set of annotations.

The dev and prod Argo CD application manifests actually already contain these annotations. Let's review them now.

Open the dev application manifest.
```editor:select-matching-text
file: ~/cat-service-release-ops/deploy/argocd-app-dev.yaml
text: `annotations:`
after: 5
```

The annotations tell Argo CD Image Updater to find the most recently published `cat-service` image whose tag matches the specified regular expression, and to update the ops repo usign the git crendentials in the "gitcred" secret.

> Note: If you want to disable Argo CD Image Updater from monitoring this image, you can delete all of the annotations or simply uncomment the one that sets ignore-tages to "*".

The prod application has the same configuration.

Since this configuration is already in place, Argo CD Image Updater will start to monitor the container registry right away.
