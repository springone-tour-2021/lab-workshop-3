## Automate deployment

Earlier in this workshop you deployed an image manually to Kubernetes using `kubectl apply...`.

One option to automate deployment would be to include this command in a shell script executed by an automation toolchain like Github Actions, Jenkins, and so on.

However, there is an alternate tool that is purpose-built for managing deployments in Kubernetes and provides a more robust set of features for managing deployments at scale and over time. This tool is called [ArgoCD](https://argo-cd.readthedocs.io/en/stable). This is the tool you will use now to automate applying the cat-service-release-ops manifests to Kubernetes.

ArgoCD runs on Kubernetes. You will install it and configure it to ensure that the cat-service deployment in Kubernetes always matches the declared state in the cat-service-release-ops repo.

### Review Argo CD installation

As with kpack, since this tutorial environment hosts many user sessions in the same cluster and there can only be one installation of argocd per cluster, argocd has already been installed.
If you are interested in installation instructions, read [this](https://argo-cd.readthedocs.io/en/stable/getting_started).

List the Custom Resource Definitions (CRDs) that argocd has added to your cluster.
```execute-1
kubectl api-resources | grep argo
```

Shortly, you will create two application resources, one for dev and the other for prod.

### Argo CD UI

At this point, you can also browse through the ArgoCD UI to get a visual sense for what it does.
> TODO: Figure out argocd UI url.
```dashboard:open-url
url: $(INGRESS_PROTOCOL)://$(SESSION_NAMESPACE)-argocd.$(INGRESS_DOMAIN)
```

Log in to the UI using the username `admin`.
To retrieve the default admin password, run:
```execute-1
ARGOCD_PW=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)
echo $ARGOCD_PW
```

### Configure ArgoCD for cat-service dev deployment

There are several ways to configure an application in ArgoCD.
You can use the UI, the `argocd` CLI, or you can use `kubectl` to apply a manifest describing the ArgoCD application resource.
You will use the declarative approach here, meaning, use `kubectl` to apply a yaml manifest.

Create the application manifest for the dev deployment.
Notice that you are instructing ArgoCD to poll the main branch of the cat-service-release-ops repository on GitHub for any changes to `manifests/overlays/dev` (and any relevant base files).
> Note: Ignore the annotations for now.
> We will talk about this in an upcoming exercise.
```editor:append-lines-to-file
file: ~/cat-service-release-ops/argocd/application-dev.yaml
text: |
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
    annotations:
    argocd-image-updater.argoproj.io/image-list: cat-service-image=gcr.io/pgtm-jlong/cat-service
    argocd-image-updater.argoproj.io/cat-service-image.update-strategy: latest
    argocd-image-updater.argoproj.io/cat-service-image.allow-tags: regexp:^b\d*\.\d{8}\.\d{6}$
    #    argocd-image-updater.argoproj.io/cat-service-image.ignore-tags: *
    argocd-image-updater.argoproj.io/write-back-method: git:secret:argocd/gitcred
    name: dev-cat-service
    namespace: argocd
    spec:
    destination:
    namespace: dev
    server: https://kubernetes.default.svc
    project: default
    source:
    path: manifests/overlays/dev
    repoURL: https://github.com/<YOUR_GITHUB_ORG_HERE>/cat-service-release-ops.git
    targetRevision: main
    syncPolicy:
    syncOptions:
    - CreateNamespace=true
    #    automated: {}
        automated:
          prune: true
```

Make sure to replace the org placeholder ith your GitHub org name.
```editor:select-matching-text
file: ~/cat-service-release-ops/argocd/application-dev.yaml
text: '<YOUR_GITHUB_ORG_HERE>'
```

Apply the application manifest.
```execute-1
kubectl apply -f ~/cat-service-release-ops/deploy/argocd-app-dev.yaml
```

You can revisit the UI to see the dev application represented visually.
You will be able to see that all of the resources included in the kustomized yaml have been deployed, including the postgres database.
You will be able to see the health of the various resources, and also see if they are "synced," meaning if the running components match the state declaration in GitHub.

> Note: The `argocd` CLI is a handy alternative, or complement, to the UI.
> Please see the ArgoCD documentation for more information about the CLI.

### Configure ArgoCD for cat-service prod deployment

Repeat these steps for the prod deployment.

First, create the manifest.
```editor:append-lines-to-file
file: ~/cat-service-release-ops/argocd/application-prod.yaml
text: |
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      annotations:
        argocd-image-updater.argoproj.io/image-list: cat-service-image=gcr.io/pgtm-jlong/cat-service
        argocd-image-updater.argoproj.io/cat-service-image.update-strategy: latest
        argocd-image-updater.argoproj.io/cat-service-image.allow-tags: regexp:^b\d*\.\d{8}\.\d{6}$
    #    argocd-image-updater.argoproj.io/cat-service-image.ignore-tags: *
        argocd-image-updater.argoproj.io/write-back-method: git:secret:argocd/gitcred
      name: prod-cat-service
      namespace: argocd
    spec:
      destination:
        namespace: prod
        server: https://kubernetes.default.svc
      project: default
      source:
        path: manifests/overlays/prod
        repoURL: https://github.com/<YOUR_GITHUB_ORG_HERE>/cat-service-release-ops.git
        targetRevision: main
      syncPolicy:
        syncOptions:
          - CreateNamespace=true
        #    automated: {}
        automated:
          prune: true
```

Make sure to replace the org placeholder ith your GitHub org name.
```editor:select-matching-text
file: ~/cat-service-release-ops/argocd/application-prod.yaml
text: '<YOUR_GITHUB_ORG_HERE>'
```

Then, apply it and check the UI to see the effect.
You should see a second Application, with all the corresponding resources.
```execute-1
kubectl apply -f ~/cat-service-release-ops/argocd/application-prod.yaml
```

## Explore ArgoCD

### Make a change to the deployment configuration

ArgoCD is monitoring the manifests on GitHub.
Try changing a value and seeing how ArgoCD responds.

Execute the folloing action block, then click on the url in the terminal to open the prod kustomization.yaml file.
```execute-1
echo https://github.com/$GITHUB_ORG/cat-service-release-ops/blob/main/manifests/overlays/prod/kustomization.yaml
```

Click the pencil icon on the right to edit the file.
Change the value of the replicas count by 1 (from 1 to 2, or 2 to 1, as appropriate).
Leave the default option to "Commit directly to the main branch." and click on the "Commit changes" button.

Return to the ArgoCD UI and watch ArgoCD automatically apply the change to the cluster.

Now try deleting the cat-service deployment in the dev namespace.
```execute-1
kubectl delete deployment dev-cat-service -n $SESSION_NAMESPACE-dev
```

After a few moments, ArgoCD will notice that the current state is out of sync with the declared state.
Check the UI to confirm that ArgoCD reports the discrepancy.
However, ArgoCD will not automatically re-apply the manifests.

Why is this?

ArgoCD has three components to its sync policies. For the cat-service dev and prod applications, we have selected to enable automatic mode for two of them, but manual mode for the third.
- `sync`: re-apply manifests if there is a change in git
- `prune`: delete resources from the cluster that are no longer in the git manifests
- `self-heal`: re-apply manifests when a change has been made manually to the cluster

Review the dev application definition.
 ```editor:select-matching-text
 file: ~/cat-service-release-ops/argocd/application-dev.yaml
 text: syncPolicy
 after: 5
 ```

Click the option in UIto re-sync the application, and ArgoCD will re-apply the manifests, including the missing deployment.

> Note: You can read more about ArgoCD sync policies [here](https://argoproj.github.io/argo-cd/user-guide/auto_sync/).

## Next Steps

In the next exercise, you will create the final link so that ArgoCD applies new app images created by kpack.



---
---
---

### Things we don't need any more but can talk about whetherto show

### Configure ArgoCD

The way in which the kustomize base and overlay files are arranged in the cat-service-release-ops repo requires that a certain kustomize build option be enabled.
To enable it within ArgoCD, run the following command.
```execute-1
yq eval \
  '.data."kustomize.buildOptions" = "--load_restrictor LoadRestrictionsNone"' \
  <(kubectl get cm argocd-cm -o yaml -n argocd) \
  | kubectl apply -f -
```