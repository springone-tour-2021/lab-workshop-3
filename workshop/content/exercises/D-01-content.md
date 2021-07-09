## Automate testing

> TODO: walk through the GitHub actions and show how they automatically run mvn tests when a commit is pushed to the repo.
> Also show how the last GitHub action force-pushes the cat-service repo into a cat-service-release repo.
> This release repo can only be updated by the pipeline, so it contains only the code from cat-release main branch that has passed testing.
> This is the repo that needs to be built for deployment to Kubernetes.
> Rough notes are included below.
> Needs to be completed/polished.

In the previous exercises you ran the tests manually, but this is not optimal. The next step is to have an automated workflow. One way is with [GitHub Actions](https://docs.github.com/en/actions). 

> TODO: What are github actions? 

### GitHub Actions workflow

There are some key tasks to automate:
- Testing
- Ensuring the app builds.
- Container builds. (You could use `spring-boot:build-image`, but you will do it with a more specialized tool in the next exercise.)

Triggering `mvn clean build` on a git commit would do all of these tasks. However, we do not want to build containers if the tests fail. We need a way to decouple these parts of the workflow. 

This can be done in different ways. We're first going to use `mvn clean deploy` to test and ensure the app builds. Then we are choosing to copy (via a forced git push) the code into a separate repository, `cat-service-release`. Presumably this release repository could have more limited write access than cat-service (e.g. only pipeline system account can write to it). And then the container will be built. We will see the container building part in the next section.

> TODO: improve this description
Now take a look at the deployment script. This script calls `mvn clean verify`, initializes the `cat-service-release` as a git respository, and pushes the code if and only if `mvn clean verify` passes. 
```editor:open-file
file: ~/cat-service/.github/workflows/deploy.sh 
```

First you pull the cat-service and it will test the code and it will be pushing the cat-service code into cat-service-release.

This first part of the script sets the `user.email` and  `user.name` to set the Author as `Booternetes CI Bot` and the email as `<>` in the commit. 
```editor:select-matching-text
file: ~/cat-service/.github/workflows/deploy.sh
text: "user.name"
before: 1
```

- creates a couple of directories
- clones SpringOne Tour Booternetes catservice-release
- it takes out `.git` to preverve it 
- It's copying from cat-service into the directory
- It copies the upstream booternetes catservice-release


Now take a look at the YAML workflow file. You can ignore the Artifactory env variables as they're not used in this workshop. You'll be storing your GitHub username and access token in the next step. 


> TODO: insert thing about the cache

... , sets up JDK 11, and lastly, calls the `deploy.sh` script.
> TODO: should we just remove Artifactory?

The `on` section is what the `job` section gets triggered by. Here we have it triggered on pushes or pull requests to the main branch. 
```editor:select-matching-text
file: ~/cat-service/.github/workflows/deploy.yaml
text: "on"
after: 5
```

The `jobs` section executes all the tasks triggered by `on`.
```editor:select-matching-text
file: ~/cat-service/.github/workflows/deploy.yaml
text: "jobs"
after: 22
```

The action `checkout@v2` checks-out your repo so your workflow can access it.
```editor:select-matching-text
file: ~/cat-service/.github/workflows/deploy.yaml
text: "checkout@v2"
```

The next action `cache@v1` caches everything from your maven repository `~/.m2` to speed up subsequent builds.
```editor:select-matching-text
file: ~/cat-service/.github/workflows/deploy.yaml
text: "cache@v1"
```

To set the workflow to use JDK 11 with the action use `actions/setup-java@v1`:
```editor:select-matching-text
file: ~/cat-service/.github/workflows/deploy.yaml
text: "actions/setup-java@v1"
```

To `run:` is used to run the `deploy.sh` script that we just looked at.
```editor:select-matching-text
file: ~/cat-service/.github/workflows/deploy.yaml
text: "run"
```

### GitHub Actions secrets

The last configuration detail to set up is to add credentials to `cat-service` so that the GitHub Actions in `cat-service` can push a copy of the tested code to `cat-service-release`. 
 To do this:
- Run this command and click on the link in terminal 1 to get to the `cat-service` repository's secrets
    ```execute-1
    echo https://github.com/$GITHUB_ORG/cat-service/settings/secrets/actions
    ```
- Create a new repository secret called `GIT_USERNAME` with your GitHub username as the value
- Create another secret called `GIT_PASSWORD` with your access token as the value

## Enable GitHub Actions

Run this command and click on the link in terminal 1 navigate to the `cat-service` repository's actions page:
```execute-1
echo https://github.com/$GITHUB_ORG/cat-service/actions
```

Click on the button to enable GitHub Actions workflows.
![alt_text](images/github-actions-enable-workflows.png "Enable GitHub Actions workflows")

### Try it out

Take a look at the contents of `cat-service-release`. It will be empty.
Run this command and click on the link in terminal 1
```execute-1
echo https://github.com/$GITHUB_ORG/cat-service-release
```

#### Commit and push a change

Now make a change and add a commit to trigger the GitHub Actions workflow. 
```execute-1
echo "+" >> bump
git add bump
git commit -m "bump"
git push
```

Now check out the logs by clicking on the Action's name and then build. You'll see a log for setting up the job, running through each of the actions in the workflow file, post logs, and completing the job. Click on any of them to check out the logs.
Run this command and click on the link in terminal 1:
```execute-1
echo https://github.com/$GITHUB_ORG/cat-service/actions
```

![alt_text](images/github-actions-logs.png "GitHub Actions logs")


#### Check contents of cat-service-release

Once the action workflow is done, check the `cat-service-release` repository again.You should now see pushed code!
Run this command and click on the link in terminal 1:
```execute-1
echo https://github.com/$GITHUB_ORG/cat-service-release
```
