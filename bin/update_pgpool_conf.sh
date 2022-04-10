#!/bin/bash
###########################
# Levente Simon

KCONF=""
NS=""
USERS=""
PASSWORDS=""

ARGS=$(getopt -o f:n:u:p:h -- $@)
eval set -- ${ARGS}
echo $ARGS > /tmp/pisi

while true; do
  case $1 in
    -f)
     if [[ $(echo $2 | cut -d: -f1) == 'base64' ]]; then
       export CONFIG_DATA=$(echo $2 | cut -d: -f2)
       KCONF="--kubeconfig <(echo \$CONFIG_DATA | base64 --decode)"
     else
       KCONF="--kubeconfig=$2"
     fi
     shift 2;;
    -n)
     NS="-n $2"
     shift 2;;
    -u)
     USERS=$2
     shift 2;;
    -p)
     PASSWORDS=$2
     shift 2;;
    -h)
     echo "Usage: $(basename $0) -f <kube-config> -n <namespace> -u <user> -p <password>"
     exit;;
    --)
     break;;
  esac
done

echo "kubectl ${KCONF} ${NS} create secret generic pool-passwd --from-literal=usernames='${USERS}' --from-literal=passwords='${PASSWORDS}' --dry-run=client -o yaml | kubectl ${KCONF} ${NS} apply -f -" > /tmp/kaki
eval "kubectl ${KCONF} ${NS} create secret generic pool-passwd --from-literal=usernames='${USERS}' --from-literal=passwords='${PASSWORDS}' --dry-run=client -o yaml | kubectl ${KCONF} ${NS} apply -f -"

sleep 5
POD=$(eval "kubectl ${KCONF} ${NS} get pods -l app.kubernetes.io/component=pgpool,app.kubernetes.io/name=postgresql-ha -o jsonpath='{.items[0].metadata.name}'"  2>/dev/null) 

sleep 2
eval "kubectl ${KCONF} ${NS} delete pod ${POD}"

while [[ $(eval "kubectl ${KCONF} ${NS} get pods -l app.kubernetes.io/component=pgpool,app.kubernetes.io/name=postgresql-ha -o jsonpath='{.items[0].status.containerStatuses[0].ready}' | grep -v true | wc -l") -gt 0 ]] ; do
  sleep 2
done
