## Automate deployment

Earlier in this workshop you deployed an image manually to Kubernetes using `kubectl apply...`.

One option to automate deployment would be to include this command in a shell script executed by an automation toolchain like Github Actions, Jenkins, and so on.

However, there is an alternate tool that is purpose-built for managing deployments in Kubernetes and provides a more robust set of features for managing deployments at scale and over time. This tool is called [ArgoCD](https://argo-cd.readthedocs.io/en/stable). This is the tool you will use now to automate applying the cat-service-release-ops manifests to Kubernetes.

ArgoCD runs on Kubernetes. You will install it and configure it to ensure that the cat-service deployment in Kubernetes always matches the declared state in the cat-service-release-ops repo.

### Review Argo CD installation

Argo CD has already been installed into the workshop cluster.
> Interested in the installation instructions? Read  [this](https://argo-cd.readthedocs.io/en/stable/getting_started).

List the Custom Resource Definitions (CRDs) that argocd has added to your cluster.
```execute-1
kubectl api-resources | grep argo
```

Shortly, you will create "Application" resources.

### Argo CD UI && CLI

At this point, you can explore the ArgoCD UI to get a visual sense for what it does.
```dashboard:open-url
url: $(INGRESS_PROTOCOL)://$(SESSION_NAMESPACE)-argocd.$(INGRESS_DOMAIN)
```

In terminal 2, start a port forwarding process so that you can connect to the Argo CD server in the argocd namespace.
```execute-2
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

At this point, you can explore the ArgoCD UI to get a visual sense for what it does.
```dashboard:create-url
url: localhost:8080
```

You can also log in using the CLI.
```execute-1
ARGOCD_PW=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)
echo $ARGOCD_PW
alias argocd='argocd --server :8080 --insecure'
argocd login localhost:8080 --username admin --password=$ARGOCD_PW
```

Check the current app list. It should be empty.
```execute-1
argocd app list
```

### Configure ArgoCD for cat-service dev deployment

There are several ways to configure an application in ArgoCD.
You can use the UI, the `argocd` CLI, or you can use `kubectl` to apply a manifest describing the ArgoCD application resource.
You will use the argocd CLI in this exercise.

Create an Argo CD `application` for the dev deployment.
Notice that you are instructing ArgoCD to poll the `educates-workshop` branch of the cat-service-release-ops repository on GitHub for any changes to `manifests/overlays/dev` (and any relevant base files).
```execute-1
argocd app create dev-cat-service \
                  --dest-namespace ${SESSION_NAMESPACE} \
                  --dest-server https://kubernetes.default.svc \
                  --repo https://github.com/${GITHUB_ORG}/cat-service-release-ops.git \
                  --revision educates-workshop \
                  --path manifests/overlays/dev \
                  --sync-policy automated \
                  --auto-prune
```

You can revisit the UI to see the dev application represented visually.
You will be able to see that all the resources included in the kustomized yaml have been deployed, including the postgres database.
You will also see some additional resource types that `kubectl get all` does not show by default.
In addition, you will see the health of the various resources, and also see if they are "synced," meaning if the running components match the manifests in GitHub.

## Explore ArgoCD

### Make a change to the deployment configuration

ArgoCD is monitoring the manifests on GitHub.
Try changing a value and seeing how ArgoCD responds.

Execute the following action block, then click on the url in the terminal to open the dev kustomization.yaml file.
```execute-1
echo https://github.com/$GITHUB_ORG/cat-service-release-ops/blob/educates-workshop/manifests/overlays/dev/kustomization.yaml
```

Make sure you are looking at the `educates-workshop` branch an click the pencil icon on the right to edit the file.
Change the value of the replicas count by 1 (from 1 to 2, or 2 to 1, as appropriate).
Leave the default option to "Commit directly to the educates-workshop branch." and click on the "Commit changes" button.

Return to the ArgoCD UI and watch ArgoCD automatically apply the change to the cluster.

Now try deleting the dev-cat-service deployment.
```execute-1
kubectl delete deployment dev-cat-service
```

After a few moments, ArgoCD will notice that the current state is out of sync with the declared state.
Check the UI to confirm that ArgoCD reports the discrepancy.
However, ArgoCD will not automatically re-apply the manifests.

Why is this?

ArgoCD has three components to its sync policies. For the cat-service dev application, we have selected to enable automatic mode for two of them, but manual mode for the third.
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

#### Optional: Deploy to prod

As an exercise, you can repeat these steps using the prod overlay.

## Next Steps

In the next exercise, you will create the final link so that ArgoCD applies new app images created by kpack.
