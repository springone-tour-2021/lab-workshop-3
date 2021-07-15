Woohoo! Your workflow is set up from beginning to end!
By committing a change to cat-service, you've _cat_alyzed it into action!
Let's trace this kitty's paw prints as it makes its way to production.

## Testing

Back on GitHub, in your `cat-service` repository, navigate back into `Actions`.
You should see a running workflow.
Click into the details to verify that the app is being tested.

## Promoting the code

Once the app is tested, the code will be promoted to release.
Check your `cat-service-release` repository on GitHub.
You should see a new commit (GitHub will tell you a new commit was made a few seconds ago).

## Containerizing

The new commit in the release repository will signal to kpack that a new container nees to be built.
kpack is polling the release repo every 5 minutes, so it may take a moment for it to kick into action, but you can monitor its progress by running the following command.
```execute-1
kubectl get builds -w
```

You should see a `build-2` appear.





Ad skopeo
## Promoting the container

The GitHub workflow you enabled in the last step has been polling the registry

Update tag workflow


