Woohoo! Your workflow is set up from beginning to end!
What's more, by committing a change to cat-service, you've _cat_alyzed the workflow into action!
Let's trace this kitty's paw prints as it makes its way to production.

## Testing

Back on GitHub, in your `cat-service` repository, navigate to `Actions`.
Your `deploy` workflow should be running.
Click into the details to verify that the app is being tested.

## Promoting the code

Once the app is tested, the code will be promoted to the release repo.
Check your `cat-service-release` repository on GitHub.
You should see a new commit (GitHub will tell you a new commit was made a few seconds ago).

## Containerizing

The new commit in the release repository will signal to kpack that a new container needs to be built.
kpack is polling the release repo every 5 minutes, so it may take a moment for it to kick into action, but you can monitor its progress by running the following command.
```execute-1
kubectl get builds -w
```

Eventually, you should see a `build-2` appear.

Once it does, you can check its progress in the build log.
Wait until you see the build is successful.
```execute-1
logs -namespace ${SESSION_NAMESPACE} -image cat-service -build 2
```

If necessary, stop the logs process.
```execute-1
<ctrl-c>
```

You can also verify that the image was published to the registry.
Note the new build tag starting with `b2`.
```execute-1
skopeo list-tags docker://$REGISTRY_HOST/cat-service
```

## Promoting the container

The GitHub workflow you enabled in the last step—`update tag`—has been polling the registry, waiting for the image to appear. Now that a new image is available, this workflow will update the value of `newTag` in the ops repo.

Return to the `Actions` section of your `cat-service` repository on GitHub.
Your `update tag` workflow should be running.
Click into the details to verify that it is running successfully.

Once it is done, you should see a new commit on your ops repo.
In GitHub, navigate to the `manifests/base/app/kustomization.yaml` file and verify that `newTag` has been updated to match the new build number.

## Deploying

Argo CD is busy polling the ops repo, so as soon as it detects the new commit created by the `update tag` workflow, it will apply the updated yaml to the cluster.

Argo CD is pretty fast—and you configured it to auto-sync—so you may not catch it saying it's out-of-sync, but you can check the cluster to see the age of the various resources.
```execute-1
kubectl get all
```

Once Argo CD reapplies the yaml, you should see the age of the `cat-service` pods reset.

If you did the optional exercise of creating a production application in Argo CD, you'll see the prod deployment updated as well.

## Conclusion

There you have it. A fully automated workflow from development to production, leveraging Kubernetes-native tools that are purpose built to streamline your operations. Now, there's more than one way to skin a cat,* but between GitHub actions, kpack, Paketo, and Argo CD, you've got an elegant solution to an age-old problem.

To boot, you've built-in tests spanning the pyramid with extra care to test persistence and integration with a modern twist with Spring Cloud Contracts, Flyway, and Testcontainers.


---
`* _Disclaimer: We highly discourage the skinning of any cats. Especially Toby. Please don't skin Toby._


