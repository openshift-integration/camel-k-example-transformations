#!/bin/bash

function waitFor() {
  for i in {1..30}; do
    sleep 5
    ("$@") && return
    echo "$i Waiting for exit code of command \"$@\"."
  done
  exit 1
}

# install Operator
SOURCE=$( dirname "${BASH_SOURCE[0]}")
sed "s/YAKS_NAMESPACE/${YAKS_NAMESPACE}/" "${SOURCE}"/../resources/postgresOperatorGroup.yaml | oc create -f - -n ${YAKS_NAMESPACE}
oc create -f "${SOURCE}"/../resources/postgresSubscription.yaml -n ${YAKS_NAMESPACE}


# ensure operator pod is deployed and Ready
waitFor oc wait pod -l name=postgresql-operator --for condition=Ready --timeout=120s -n ${YAKS_NAMESPACE}

#create database
oc create -f "${SOURCE}"/../resources/postgres.yaml -n ${YAKS_NAMESPACE} 

# wait for the postgres pod to be created
waitFor oc wait pod -l cr=mypostgres --for condition=Ready --timeout=120s -n ${YAKS_NAMESPACE}

# populate database
PGPOD=$(oc get pods -l cr=mypostgres -o name -n ${YAKS_NAMESPACE})
oc rsync -n ${YAKS_NAMESPACE} "${SOURCE}"/../sql $PGPOD:/tmp/
oc exec -n ${YAKS_NAMESPACE} $PGPOD -- chmod +x /tmp/sql/populate.sh
oc exec -n ${YAKS_NAMESPACE} $PGPOD -- ls -l /tmp/sql/
oc exec -n ${YAKS_NAMESPACE} $PGPOD -- /tmp/sql/populate.sh