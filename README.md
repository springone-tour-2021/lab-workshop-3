---
Contributing to workshop
Prerequisites: Minikube

To start workshop
```bash
sh local-eduk8s-start.sh
```
### Set up
1. Clone the repo
2. Create your development branch `git checkout -b <my-branch>`
3. Going to `resources/workshop.yaml` in `spec.content.files` you will find the url to the files, something like: 
```yaml
files: github.com/everythingeverywhere/lab-contributors?ref=main
```
4. Change the last part of the url `?ref=main` to `?ref=<your-branch-name`

### What will the above affect?
The feild `spec.content.files` is where you tell educates to get your lab's files. This will be used to make the workshop by the platform. 

As you develop and commit to your branch you can now see the changes, if for instance, you change it to `main` it will use the files from the `main` branch.

### Development

1. Instructions - written in markdown and stored under `workshop/content/exercises`


2. After adding new files, you are required to update `workshop/modules.yaml` and `workshop/workshop.yaml`. 

> These config files tell educates:
> - The order of the instructions from your markdown in `workshop/workshop.yaml` by specifying the filepath without ending in `.yaml`.
> - Similarly, in `workshop/modules.yaml` the filepath is used as well to order and specify the instruction. The `name` field will appear as the title of the instruction and the `exit_sign` is the text on the button to click next.

One of the core features of educates is the **clickable actions**, these are actions the user clicks in the instructions that will be automatically execute for them.

Clickable actions should be used for every step possible. This for many reasons but mainly to reduce user error, even for users with a lot of experience they can make mistakes typing and using copy/paste. Also, the


--
Workshop content using Markdown formatting for pages.

For more detailed information on how to create and deploy workshops, consult
the documentation for eduk8s at:

* https://docs.eduk8s.io

If you already have the eduk8s operator installed and configured, as well as having this repo cloned to deploy
and view this sample workshop, run:

```
kubectl apply -f ./resources/workshop.yaml
kubectl apply -f ./resources/training-portal.yaml
```

This will deploy a training portal hosting just this workshop. To get the
URL for accessing the training portal run:

```
kubectl get trainingportal
```

The training portal is configured to allow anonymous access. For your own
workshop content you should consider removing anonymous access.
