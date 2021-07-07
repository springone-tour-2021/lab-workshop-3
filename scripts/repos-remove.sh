#!/usr/bin/bash

if [[ ! "${GITHUB_USER}" == ""  && ! "${GITHUB_TOKEN}" == ""  && ! "${GITHUB_ORG}" == "" ]]; then
  echo "Deleting repos from GitHub."
  hub delete "${GITHUB_ORG}"/cat-service -y
  hub delete "${GITHUB_ORG}"/cat-service-release -y
  hub delete "${GITHUB_ORG}"/cat-service-release-ops -y
  echo
  echo "Deleting clone repo directories."
  rm -rf ~/cat-service
  rm -rf ~/cat-service-release
  rm -rf ~/cat-service-release-ops
else
  echo "!!!!! ERROR !!!!!"
  echo
  echo "GITHUB_USER, GITHUB_TOKEN, and/or GITHUB_ORG have not been properly set in this terminal."
  echo "Please run the credentials script and try again."
fi
