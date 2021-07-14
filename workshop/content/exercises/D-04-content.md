Any update to the manifests will be detected by Argo CD.

What happens after kpack publishes a new image?
Right now, nothing.
This means Argo CD won't know that a new image is available.

This problem can be solved in different ways.
In this workshop, we are going to use GitHub Actions.

### GitHub Actions secrets

You will need to add a few more secrets for this section. You'll need the registry host, registry username, and registry password.
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
Create a secret called `REGISTRY_USERNAME` with the username and a secret called `REGISTRY_PASSWORD` with the password.

### Create a new GitHub Actions workflow

The next part is to have the existing GitHub Actions workflow kick off a new workflow to update ...
> TODO: continue this

The Update Tag workflow will be launched when a dispatch request is sent to the `cat-service` repository. Sending this request will be shown in the next section.
> TODO: What is a dispatch...is this actually a request? Verify

```editor:select-matching-text
file: ~/cat-service/.github/workflows/update-tag.yaml
text: "on"
after: 2
```

> TODO: Explain script. If there is time, than can select different parts of the script to explain such as the skopeo command.

```editor:open-file
file: ~/cat-service/.github/workflows/update-tag.sh
```

### Update previous GitHub Actions workflow to deploy new workflow

The following will send the dispatch via curl. It is sending the event type `tag` which is what the Update Tag workflow expects. It is being added to the end of the Deploy workflow.

```editor:select-matching-text
file: ~/cat-service/.github/workflows/deploy.yaml
text: "Update Tag"
after: 6
```

Uncomment the lines:

```editor:execute-command
command: editor.action.commentLine
```

> TODO: create new commit and push to `cat-service`

