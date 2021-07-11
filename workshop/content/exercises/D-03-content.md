You could automate deployment by adding `kubectl apply -k...` to your automation scripts using Github Actions, Jenkins, or any similar toolchain.

However, there is another tool that provides a more robust set of features for managing deployments at scale and over time. This tool is called [Argo CD](https://argo-cd.readthedocs.io/en/stable).

In this exercise, you will use `Argo CD` to automate the deployment of `Cat Service` and ensure that the deployment stays true to the manifests.

## Review Argo CD installation

Argo CD has already been installed into the workshop cluster.

_Interested in the installation instructions? Read  [this](https://argo-cd.readthedocs.io/en/stable/getting_started)._

List the Custom Resource Definitions (CRDs) that Argo CD has added to your cluster.
```execute-1
kubectl api-resources | grep argo
```

Shortly, you will create "Application" resources.

### Terminal setup

For convenience, set the following shortcuts in both terminal windows.
```execute-all
#alias argocd='argocd --server :8080 --insecure'
ARGOCD_PW=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d)
```

Also, in terminal 2, start a port forwarding process so that you can communicate with the Argo CD server in the argocd namespace. Keep this process running throughout this exercise.
```execute-2
kubectl port-forward svc/argocd-server -n argocd 8080:80
```

### Argo CD Web UI

At this point, you can explore the Argo CD UI to get a visual sense for what it does.
```dashboard:open-url
url: $(INGRESS_PROTOCOL)://$(SESSION_NAMESPACE)-argocd.$(INGRESS_DOMAIN)
```

---
OR:

At this point, you can explore the Argo CD UI to get a visual sense for what it does.
```dashboard:create-dashboard
name: Argo CD
url: http://localhost:8080/
```
---

Log in as `admin`. To retrieve the password, run:
```execute-1
echo $ARGOCD_PW
```

### Argo CD CLI

```execute-1
argocd login localhost:8080 --username admin --password=$ARGOCD_PW --insecure
```

To see some available commands, run `argocd --help`, or simply:
```execute-1
argocd
```

## Set up the dev application

There are several ways to configure an application in Argo CD.
You can use the UI, the `argocd` CLI, or you can use `kubectl` to apply a manifest describing the Argo CD application resource.
In this exercise, you will use the CLI.

Before continuing, you will need to update the 'newName' field in `manifests/base/app/kustomization.yaml` on GitHub, as Argo CD will be using the remote copy of the file.
You can navigate to the file on GitHub or run this command and click on the link in terminal 1:
```execute-1
https://github.com/${GITHUB_ORG}/cat-service-release-ops/blob/educates-workshop/manifests/base/app/kustomization.yaml
```
Click on the pencil icon to edit, replace `MY_REGISTRY` with the following value, and click on "Commit changes."
```execute-1
echo $REGISTRY_HOST
```

Create an Argo CD `application` for the dev deployment.
Notice that you are instructing Argo CD to poll the `educates-workshop` branch of the cat-service-release-ops repository on GitHub for any changes to `manifests/overlays/dev` (and any relevant base files).
```execute-1
argocd app create dev-cat-service-${SESSION_NAMESPACE} \
                  --label session=${SESSION_NAMESPACE} \
                  --dest-namespace ${SESSION_NAMESPACE} \
                  --dest-server https://kubernetes.default.svc \
                  --repo https://github.com/${GITHUB_ORG}/cat-service-release-ops.git \
                  --revision educates-workshop \
                  --path manifests/overlays/dev \
                  --sync-policy automated \
                  --auto-prune
```

You can revisit the UI to see the application represented visually.
You will all the resources related to the deployment - app and database resources, including resource types that `kubectl get all` does not show by default.
In addition, you will see the health of the various resources, and also see if they are "synced," meaning if the running components match the manifests in GitHub.

You can also check the status using the CLI.
```execute-1
argocd app list --label session=${SESSION_NAMESPACE}
```

## Explore Argo CD

### Make a change to the deployment configuration

Argo CD is monitoring the manifests on GitHub.
Try changing a value and seeing how Argo CD responds.

Execute the following action block, then click on the url in the terminal to open the dev kustomization.yaml file.
```execute-1
echo https://github.com/$GITHUB_ORG/cat-service-release-ops/blob/educates-workshop/manifests/overlays/dev/kustomization.yaml
```

Make sure you are looking at the `educates-workshop` branch an click the pencil icon on the right to edit the file.
Change the value of the replicas count by 1 (from 1 to 2, or 2 to 1, as appropriate).
Leave the default option to "Commit directly to the educates-workshop branch." and click on the "Commit changes" button.

Return to the Argo CD UI and watch Argo CD automatically apply the change to the cluster.

Now try deleting the dev-cat-service deployment.
```execute-1
kubectl delete deployment dev-cat-service
```

After a few moments, Argo CD will notice that the current state is out of sync with the declared state.
Check the UI to confirm that Argo CD reports the discrepancy.
However, Argo CD will not automatically re-apply the manifests.

Why is this?

Argo CD has three components to its sync policies. For the cat-service dev application, we have selected to enable automatic mode for two of them, but manual mode for the third.
- `sync`: re-apply manifests if there is a change in git
- `prune`: delete resources from the cluster that are no longer in the git manifests
- `self-heal`: re-apply manifests when a change has been made manually to the cluster

Review the dev application definition.
 ```editor:select-matching-text
 file: ~/cat-service-release-ops/argocd/application-dev.yaml
 text: syncPolicy
 after: 5
 ```

Click the option in UI to re-sync the application, and Argo CD will re-apply the manifests, including the missing deployment.

> Note: You can read more about Argo CD sync policies [here](https://argoproj.github.io/argo-cd/user-guide/auto_sync/).

## Deploy to prod

As an exercise, you can repeat these steps using the prod overlay.

## Next Steps

In the next exercise, you will create the final link so that Argo CD applies new app images created by kpack.
