#!/bin/bash
#!/bin/bash -x

START_DIR=$(pwd)
WORK_DIR=$(cd `dirname $0`/ && pwd )
cd $WORK_DIR

workshops=(eduk8s-labs-w16 eduk8s-labs-w24)
#WKSHP_NAME=lab-springone-tour-devops-
#WKSHP_ID=01

# Start fresh from roles in template
mv policy.csv policy.csv.backup
cat policy-role-template.csv > policy.csv

# Add a line per session for a given workshop id
for WORKSHOP in "${workshops[@]}"; do
  for i in $(seq -f "%03g" 1 20); do
    SESSION_USER=$WORKSHOP-s$i
    SESSION_PASSWORD=$RANDOM
    TIMESTAMP=2021-01-01T12:00:00Z

    echo "g, $SESSION_USER, role:session-user" >>  policy.csv

    kubectl --kubeconfig=/Users/ciberkleid/Downloads/kubeconfig-s1tour-july-test-a2edc10.yml \
            create secret generic argocd-initial-${SESSION_USER}-secret \
            -n argocd \
            --from-literal=password='${SESSION_PASSWORD}'

    kubectl --kubeconfig=/Users/ciberkleid/Downloads/kubeconfig-s1tour-july-test-a2edc10.yml \
            -n argocd patch secret argocd-secret -p "$(cat <<EOF
{"stringData": {
  "accounts.$SESSION_USER.password": "$(htpasswd -nbBC 10 $SESSION_USER $SESSION_PASSWORD | cut -d : -f 2)",
  "accounts.$SESSION_USER.passwordMtime": "2021-01-01T12:00:00Z"
}}
EOF
)"
  done
done

cd $START
