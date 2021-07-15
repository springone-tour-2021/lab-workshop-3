Any update to the manifests will be detected by Argo CD.

What happens after kpack publishes a new image?
Right now, nothing.
This means Argo CD won't know that a new image is available.

This problem can be solved in different ways.
In this workshop, we are going to use GitHub Actions.

### Update Tag GitHub Actions workflow

When kpack pushes a new image, we want to update the `newTag` field in the manifest file with the newest tag kpack created. Since Argo CD watches the `cat-service-release-ops` repository it will then know there is a change (new image) and apply the manifest.

```editor:select-matching-text
file: ~/cat-service-release-ops/manifests/base/app/kustomization.yaml
text: "newTag"
```

We will use a new GitHub Actions workflow named Update Tag. We want this workflow to be launched from the previous Deploy workflow after it runs the tests and pushes the code to `cat-service-release`. To trigger this new workflow, we will use a [repository_dispatch event](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#repository_dispatch). 

The following code will send the dispatch event via curl to GitHub. 
It is sending the event type `tag`.
You will later uncomment this section in the browser. 

```editor:select-matching-text
file: ~/cat-service/.github/workflows/deploy.yaml
text: "Update Tag"
after: 6
```

Here you can see that the Update Tag workflow is triggered by repository dispatches with the `tag` event type.

```editor:select-matching-text
file: ~/cat-service/.github/workflows/update-tag.yaml
text: "on"
after: 2
```

We are then cloning down `cat-service` and running a custom script `update-tag.sh`.
`update-tag.sh` gets the newest tag that kpack pushed to the registry and checks to see if it is newer than the tag in them manifest (`kustomization.yaml`). If it is, it updates the tag.

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
Create the three repository secrets:
- `REGISTRY_HOST` - with the registry host as the value
- `REGISTRY_USERNAME` - with the registry username as the value
- `REGISTRY_PASSWORD` - with the registry password as the value

### Update the Deploy Workflow

Now it's time to actually uncomment those lines in the Deployment workflow that trigger the Update Tag workflow.
Open the `.github/workflows/deploy.yaml` in your repo. 
You can use the following action to generate a link to the right page.

```execute-1
echo https://github.com/$GITHUB_ORG/cat-service/blob/educates-workshop/.github/workflows/deploy.yaml
```

Click the edit button on the right hand side of the window; it's a pencil icon.
![alt_text](images/ga-edit-file.png "Click edit file to edit the file")

Uncomment the commented out lines.
Hit the "Start commit" button then click "Commit changes".

This commit to `cat-service` will automatically trigger the entire workflow from beginning to end since the Deploy workflow is triggered by pushes. We will trace through this in the next section. 
