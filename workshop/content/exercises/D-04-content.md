Any update to the manifests will be detected by Argo CD.

What happens after kpack publishes a new image?
Right now, nothing.
This means Argo CD won't know that a new image is available.

This problem can be solved in different ways.
In this workshop, we are going to use GitHub Actions.

### Update Tag GitHub Actions workflow

When kpack pushes a new image, we want to update the `newTag` field in `/cat-service-release-ops/manifests/base/app/kustomization.yaml` with the newest tag kpack created. Since Argo CD watches the `cat-service-release-ops` repository it will then know there is a change (new image) and do a `kubectl apply`.

```editor:select-matching-text
file: ~/cat-service-release-ops/manifests/base/app/kustomization.yaml
text: "newTag"
```

This will be done with a new GitHub Actions workflow named Update Tag. 
The Update Tag workflow will be launched from the previous Deploy workflow. This can be done via a [`repository_dispatch` event](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#repository_dispatch) to trigger the workflow. 

The following code at the end of the Deploy workflow will send the dispatch event via curl. You will later uncomment this section in the browser. 
It is sending the event type `tag`.

```editor:select-matching-text
file: ~/cat-service/.github/workflows/deploy.yaml
text: "Update Tag"
after: 6
```

Here you can see that the Update Tag workflow is triggered on the `tag` event type for a repository dispatch.

```editor:select-matching-text
file: ~/cat-service/.github/workflows/update-tag.yaml
text: "on"
after: 2
```

It then clones down `cat-service` and runs the script `update-tag.sh`.
`update-tag.sh` gets the newest tag that kpack pushed to the registry and checks to see if it is newer than the tag in `kustomization.yaml`. If it is, it updates it.

```editor:open-file
file: ~/cat-service/.github/workflows/update-tag.sh
```
### GitHub Actions secrets

You will need to add a few more secrets for this new workflow. You'll need the registry host, registry username, and registry password.
To get these values, run this command:
```execute-1
echo "REGISTRY_HOST:     $REGISTRY_HOST
REGISTRY_USERNAME: $REGISTRY_USERNAME
REGISTRY_PASSWORD: $REGISTRY_PASSWORD"
```

Run this command and click on the link in terminal 1 to get to the `cat-service` repository's secrets
```execute-1
echo https://github.com/$GITHUB_ORG/cat-service/settings/secrets/actions
```
Create a new repository secret called `REGISTRY_HOST` with the registry host.
Also create a secret called `REGISTRY_USERNAME` with the username and a secret called `REGISTRY_PASSWORD` with the password.

### Update the Deploy Workflow

Open `cat-service/.github/workflows/deploy.yaml` in your repo by clicking the next command to get a link in terminal-1. 

```execute-1
echo https://github.com/$GITHUB_ORG/cat-service/blob/educates-workshop/.github/workflows/deploy.yaml
```

Click the edit button on the right hand side of the window; it's a pencil icon.
![alt_text](images/ga-edit-file.png "Click edit file to edit the file")

Uncomment the commented lines. 
Hit the "Start commit" button then click "Commit changes".

Now the existing Deploy workflow will launch the Update Tag workflow.

This commit to `cat-service` will trigger the entire workflow from beginning to end. We will trace through this in the next section. 
