#!/bin/bash

oc new-project image-uploader --display-name='Image Uploader Project'
oc new-app centos/ruby-22-centos7~https://github.com/openshift/ruby-ex.git
oc new-app --image-stream=php --code=https://github.com/OpenShiftInAction/image-uploader.git --name=app-cli
oc describe svc/app-cli
oc expose svc/app-cli
oc describe route/app-cli
oc scale dc/app-cli --replicas=2
oc scale dc/app-cli --replicas=1
oc get pods --show-all=false
oc exec app-cli-1-9hsz1 hostname

lsns -p 4470
nsenter --target 2385
nsenter -t 5136 -n /sbin/ip a
docker inspect -f '{{ .GraphDriver.Data.DeviceName }}' fae8e211e7a7
pgrep -f dockerd-current
lsns -p 2385
docker exec fae8e211e7a7 hostname
ps --ppid 4470
oc exec app-cli-1-18k2s ps

oc describe rc $(oc get rc -l app=app-cli -o=jsonpath='{.items[].metadata.name}')
oc get rc app-cli-1 -o yaml
oc delete pod -l app=app-cli
oc describe svc app-cli | grep Selector
oc scale dc app-cli-1 --replicas=1
oc set probe dc/app-cli \
--readiness \
--get-url=http://:8080/notreal \
--initial-delay-seconds=5
oc get pods

oc project openshift-infra
ansible-playbook -i /root/hosts /usr/share/ansible/openshift-ansible/playbooks/byo/openshift-cluster/openshift-metrics.yml
-e openshift_metrics_install_metrics=True \
-e openshift_metrics_start_cluster=True \
-e openshift_metrics_duration=1 \
-e openshift_metrics_hawkular_hostname=hawkular-metrics.apps.192.168.122.101.nip.io

oc autoscale dc/app-cli
--min 2
--max 5
--cpu-percent=75
oc get pods -l app=app-cli
oc get hpa
oc describe hpa app-cli
oc set resources dc app-cli --requests=cpu=400m

ab -n 50000 -c 500 http://app-cli-route-image-uploader.apps.192.168.122.101.nip.io/

oc new-project dev --display-name="ToDo App - Dev"
oc create -f https://raw.githubusercontent.com/OpenShiftInAction/chapter6/master/openshift-cicd-flask-mongo/OpenShift/templates/
dev-todo-app-flask-mongo-gogs.json -n dev
oc new-app --template="dev/dev-todo-app-flask-mongo-gogs"
oc describe imagestream todo-app-flask-mongo | grep sha256
oc tag todo-app-flask-mongo@sha256:55f29438305f9d8b6baf7ac0df8ee17965bb62a1dba8ac01190ad88e0ca18843

oc new-project test --display-name="ToDo App - Test"
oc new-app \
-e MONGODB_USER=oiatestuser \
-e MONGODB_PASSWORD=password \
-e MONGODB_DATABASE=tododb \
-e MONGODB_ADMIN_PASSWORD=password mongodb:3.2

oc policy add-role-to-group \
system:image-puller \
system:serviceaccounts:test \
-n dev

oc new-app dev/todo-app-flask-mongo:promoteToTest
oc patch svc todo-app-flask-mongo --type merge \
--patch '{"spec":{"ports":[{"port": 8080, "targetPort": 5000 }]}}'
oc expose svc todo-app-flask-mongo
oc get pods
oc rollout latest dc/todo-app-flask-mongo -n test
oc patch dc todo-app-flask-mongo --patch '{"spec":{"triggers": [{
  "imageChangeParams": {
  "automatic": true,
  "containerNames": [
  "todo-app-flask-mongo"
  ],
  "from": {
  "kind": "ImageStreamTag",
  "name": "todo-app-flask-mongo:promoteToTest",
  "namespace": "dev"
  }
  },
  "type": "ImageChange"
  }
  ]
oc set triggers
}}'

oc create secret generic oia-prod-secret \
--from-literal=mongodb_user=oiauser \
--from-literal=mongodb_password=SecretPwd12 \
--from-literal=mongodb_hostname=mongodb \
--from-literal=mongodb_database=tododb

oc set volumes dc/todo-app-flask-mongo \
--add \
--name=secret-volume \
--mount-path=/opt/app-root/mongo/ \
--secret-name=oia-prod-secret

oc logs $(oc get pods -l deploymentconfig=todo-app-flask-mongo \
-o=jsonpath='{.items[].metadata.name}')

echo "usebuttons" > style.properties
oc create configmap \
ui-config \
--from-file=style.properties

oc set volumes dc/todo-app-flask-mongo \
--add \
--name=configmap-volume \
--mount-path=/opt/app-root/ui/ \
-t configmap --configmap-name=ui-config

oc policy add-role-to-user edit \
system:serviceaccount:cicd:jenkins -n dev

oc policy add-role-to-user edit \
system:serviceaccount:cicd:jenkins -n test

oc policy add-role-to-user edit \
system:serviceaccount:cicd:jenkins -n prod

oc new-project cicd --display-name="ToDo App - CI/CD with Jenkins"
oc create -f \
https://raw.githubusercontent.com/OpenShiftInAction/chapter6/master/jenkins-s2i/jenkins-s2i-template.json
oc new-app --template="cicd/jenkins-oia"


echo $(oc get dc todo-app-flask-mongo -o=jsonpath='{.spec.strategy.type}' -n dev)
echo $(oc get dc mongodb -o=jsonpath='{.spec.strategy.type}' -n dev)

/etc/origin/master/admin.kubeconfig  < The configuration file for system:admin is created on the master server

oc --config ~/admin.kubeconfig create -f pv01.yaml
oc --config ~/admin.kubeconfig get pv
oc get pvc

oc volume dc/app-cli --add \
--type=persistentVolumeClaim \
--claim-name=app-cli \
--mount-path=/opt/app-root/src/uploads

oc describe dc/app-cli
