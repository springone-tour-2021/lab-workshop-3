## Automate testing

> TODO: walk through the GitHub actions and show how they automatically run mvn tests when a commit is pushed to the repo
> Also show how the last GitHub action force-pushes the cat-service repo into a cat-service-release repo.
> This release repo can only be updated by the pipeline, so it contains only the code from cat-release main branch that has passed testing.
> This is the repo that needs to be built for deployment to Kubernetes.

### GitHub Actions secrets

The last configuration detail to set up is adding credentials to `cat-service` so that the GitHub Actions in `cat-service` can push a copy of the tested code to `cat-service-release`. 
 To do this:
- In your browser, navigate to the `cat-service` repository
- Navigate to Settings -> Secrets -> New repository secret.
- Create a secret called GIT_USERNAME with your GitHub username as the value
- Create another secret called GIT_PASSWORD with your access token as the value
