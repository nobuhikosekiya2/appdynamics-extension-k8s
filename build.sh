#!/bin/sh

BASEDIR=`dirname $0`

if [ `ls $BASEDIR/extensions | wc -l` -eq 0 ]; then
  echo "Please place extension zip files under $BASEDIR/extensions."
  echo "exiting error 1."
  exit 1
fi


# 1. Create extension docker image
rm -fr $BASEDIR/docker/extensions

for extension_zipfile in `ls $BASEDIR/extensions`
do
  unzip $BASEDIR/extensions/$extension_zipfile -d $BASEDIR/docker/extensions
done

docker build $BASEDIR/docker -t appdynamics-extensions:latest


# 2. create Kubernetes deployment spce yaml
configmap_def=""
volume_mount_def=""

for extension_dir in `ls $BASEDIR/docker/extensions`
do
  configmap_def="$configmap_def --from-file=${extension_dir}-config.yml=$BASEDIR/docker/extensions/$extension_dir/config.yml"
  volume_mount_def="$volume_mount_def
        - key: ${extension_dir}-config.yml
          path: extensions/${extension_dir}/config.yml"
done

cp $BASEDIR/deploy/machine-agent-extension-base.yaml $BASEDIR/deploy/machine-agent-extension.yaml
echo "$volume_mount_def" >> $BASEDIR/deploy/machine-agent-extension.yaml
echo "---" >> $BASEDIR/deploy/machine-agent-extension.yaml
kubectl create configmap -n appdynamics --dry-run=client appdynamics-extension-config $configmap_def --output yaml >>  $BASEDIR/deploy/machine-agent-extension.yaml

