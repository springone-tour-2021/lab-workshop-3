#!/usr/bin/env bash
set -e
set -o pipefail

function install_cluster_add_ons() {
  printf "\nInstalling add-ons\n"
  URL_BASE="https://raw.githubusercontent.com/booternetes-III-springonetour-july-2021/cat-service-release-ops/main"

  printf "\nInstalling add-on: kpack\n"
  kubectl apply -f "$URL_BASE/tooling/kpack/release.yaml"
  kubectl apply -f "$URL_BASE/tooling/kpack-config/stack.yaml"
  kubectl apply -f "$URL_BASE/tooling/kpack-config/store.yaml"

  printf "\nInstalling add-on: argocd\n"
  kubectl create ns argocd
  kubectl apply -f "$URL_BASE/tooling/argocd/install.yaml" -n argocd

  printf "\nInstalling add-on: argocd-image-updater\n"
  kubectl apply -f "$URL_BASE/tooling/argocd-image-updater/install.yaml" -n argocd

  printf "\nFinished installing add-ons\n"
}
