## Automate testing

> TODO: walk through the GitHub actions and show how they automatically run mvn tests when a commit is pushed to the repo.
> Also show how the last GitHub action force-pushes the cat-service repo into a cat-service-release repo.
> This release repo can only be updated by the pipeline, so it contains only the code from cat-release main branch that has passed testing.
> This is the repo that needs to be built for deployment to Kubernetes.
> Rough notes are included below.
> Needs to be completed/polished.

### Review GitHub Actions definitions

Key to automate:
test and ensure app builds (mvn clean verify)
and container builds (could do spring-boot:build-image, but will do it with a more specialized tool in the next exercise)

Dilemma:
don't want the same git commit to trigger testing and building containers because you don't actually want containers to be built for code that does not pass testing.
Key to trigger container build after tests pass.
So - how to decouple these parts of the workflow?
This can be done in different ways.
Here choosing to use "git push --force" to copy code to a separate repo, cat-service-release.
Presumably this release repo could have more limited write access than cat-service (e.g. only pipeline system account can write to it)

```editor:open-file
file: ~/cat-service/.github/workflows/deploy.sh
```

```editor:open-file
file: ~/cat-service/.github/workflows/deploy.yaml
```

### GitHub Actions secrets

The last configuration detail to set up is adding credentials to `cat-service` so that the GitHub Actions in `cat-service` can push a copy of the tested code to `cat-service-release`. 
 To do this:
- In your browser, navigate to the `cat-service` repository
- Navigate to Settings -> Secrets -> New repository secret.
- Create a secret called GIT_USERNAME with your GitHub username as the value
- Create another secret called GIT_PASSWORD with your access token as the value

(may also be able to do this with gh CLI)

Run this command and click on the link in the terminal
```execute-1
echo https://github.com/$GITHUB_ORG/cat-service/settings/secrets/actions
```

## Enable GitHub Actions

- In your browser, navigate to the `cat-service` repository
- Navigate to Actions

Run this command and click on the link in the terminal
```execute-1
echo https://github.com/$GITHUB_ORG/cat-service/actions
```

Will see this image:
![alt_text](images/github-actions-enable-workflows.png "Enable GitHub Actions workflows")

Click on the button

(may also be able to do this with gh CLI)


### Try it out

Show contents of cat-service-release before (empty)
Run this command and click on the link in the terminal
```execute-1
echo https://github.com/$GITHUB_ORG/cat-service-release
```

#### Commit a change (can be a + sign in the bump file) and push the change to cat-service.

echo "+" >> bump
git add bump
git commit -m "bump"
git push

Open again:
Run this command and click on the link in the terminal
```execute-1
echo https://github.com/$GITHUB_ORG/cat-service/actions
```

Drill in to see the logs

#### Show contents of cat-service-release before (not empty)

when the action workflow is done, check the following repo, notice the code was pushed
Run this command and click on the link in the terminal
```execute-1
echo https://github.com/$GITHUB_ORG/cat-service-release
```
