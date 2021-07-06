Sandbox area:

> TODO:
> 1. Update to us [gh](https://github.com/cli/cli) instead of hub ????
>
> 2. Figure out how to use gh help secret set
>
> 3. change to `git clone -b 1.0`

```shell
gh secret set GIT_USERNAME -b"${GITHUB_USER}" --org=${GITHUB_ORG} --repos ${GITHUB_ORG}/cat-service
gh secret set GIT_PASSWORD
```