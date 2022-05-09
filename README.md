# Kubecon 2022 - kpack Workshop

This repo contains a hands-on workshop on building images using kpack.covering the following topics:
    - kpack

The workshop can be run using [educates](https://docs.edukates.io), a system for hosting interactive workshop environments.
Educates can run on any Kubernetes cluster.

---
## Run locally

Create a cluster to host this workshop:
```shell
git clone https://github.com/vmware-tanzu-labs/educates-local-dev.git
cd educates-local-dev
brew install kctrl
./create-cluster
cd ..
```

Deploy this workshop content:
```shell
git clone https://github.com/springone-tour-2021/lab-workshop-3.git
cd lab-workshop-3
git checkout kubecon2022
```

When startup is complete, run `kubectl get trainingportal` and click on the link, or simply run `make open-workshop`.

When the workshop opens in your browser, click on the `Start workshop` button and follow the workshop instructions.

> See below for instructions to "Run on existing Kubernetes cluster"

---
## Contributing to the workshop

### Setup
Educates loads the workshop content from a git repo specified in the file [resources/workshop.yaml](resources/workshop.yaml), under the path `spec.content.files`.
In order to test your workshop contributions before submitting a pull request to merge your changes into the main branch, you can change this value to point to your own branch or fork of this repo.
In this way, you can run the workshop locally as many times as you need, pulling the workshop files from your own branch or fork.

Assuming you are working off of a branch in this repo:
1. Clone the repo
2. Create your development branch `git checkout -b <my-branch>`
3. Open the file [resources/workshop.yaml](resources/workshop.yaml) and follow the YAML path to `spec.content.files`.
   The value will be the url to the workshop files, something like: 
```yaml
files: github.com/springone-tour-2021/lab-workshop-3?ref=main
```
4. Change the last part of the url `?ref=main` to `?ref=<your-branch-name>`

Now, you can iterate locally using Minikube, pulling files with your workshop contributions from your branch, until you are ready to merge your changes into the main branch.

> Note: This change only needs to be made on your local machine.
> Avoid pushing this change to GitHub, and in particular, avoid pushing this change to the main branch of the repo.

### Development

1. Instructions - written in markdown and stored under [workshop/content/exercises](workshop/content/exercises)

> One of the core features of educates is **clickable actions**.
> These are actions the user clicks in the instructions that will be automatically executed for them.
> Clickable actions should be used for every step possible.
> This for many reasons but mainly to reduce user error.


2. After adding new files, you are required to update [workshop/modules.yaml](workshop/modules.yaml) and [workshop/workshop.yaml](workshop/workshop.yaml. 

> These config files tell educates:
> - The order of the instructions from your markdown in `workshop/workshop.yaml` by specifying the filepath without ending in `.yaml`.
> - Similarly, in `workshop/modules.yaml` the filepath is used as well to order and specify the instruction. The `name` field will appear as the title of the instruction and the `exit_sign` is the text on the button to click next.

### More information

Workshop content uses Markdown formatting for pages.

For more detailed information on how to create and deploy workshops, consult the documentation for eduk8s at:

* https://docs.eduk8s.io

---
## Run on existing Kubernetes cluster

If you already have the Educates operator installed and configured on a Kubernetes cluster, you can simply run:

```
kubectl apply -f ./resources/workshop.yaml
kubectl apply -f ./resources/training-portal.yaml
```

This will deploy a training portal hosting just this workshop. 
To get the URL for accessing the training portal run:

```shell
kubectl get trainingportal
```

The training portal is configured to allow anonymous access. 
For your own workshop content you should consider removing anonymous access.
