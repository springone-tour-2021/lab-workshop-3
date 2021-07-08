#!/usr/bin/env bash
set -e
set -o pipefail

function install_cluster_add_ons() {
  printf "\nInstalling add-ons\n"
  URL_BASE="https://raw.githubusercontent.com/booternetes-III-springonetour-july-2021/cat-service-release-ops/main"

  # Delete and reinstall kpack
  printf "\nDeleting add-on: kpack\n"
  kubectl delete --ignore-not-found -f "$URL_BASE/tooling/kpack/release.yaml"
  printf "\nInstalling add-on: kpack\n"
  kubectl apply -f "$URL_BASE/tooling/kpack/release.yaml"

  # Delete and reinstall argocd
  printf "\nDeleting add-on: argocd\n"
  kubectl delete --ignore-not-found -f "$URL_BASE/tooling/argocd/install.yaml" -n argocd
  kubectl delete --ignore-not-found -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
EOF
  printf "\nInstalling add-on: argocd\n"
  kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
EOF
  kubectl apply -f "$URL_BASE/tooling/argocd/install.yaml" -n argocd

  # Delete and reinstall argocd-image-updater
  printf "\nDeleting add-on: argocd-image-updater\n"
  kubectl delete --ignore-not-found -f "$URL_BASE/tooling/argocd-image-updater/install.yaml" -n argocd
  printf "\nInstalling add-on: argocd-image-updater\n"
  kubectl apply -f "$URL_BASE/tooling/argocd-image-updater/install.yaml" -n argocd

  printf "\nFinished installing add-ons\n"
}
