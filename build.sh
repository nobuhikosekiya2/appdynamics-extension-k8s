#!/bin/sh

BASEDIR=`dirname $0`

while getopts t: OPT
do
  case $OPT in
    "t" ) TAG="$OPTARG" ;;
  esac
done

if [ "$TAG" == "" ]; then
  TAG=appdynamics-extensions:latest
fi

if [ `ls $BASEDIR/extensions | wc -l` -eq 0 ]; then
  echo "Please place extension zip files under $BASEDIR/extensions."
  echo "exiting error 1."
  exit 1
fi


# 1. Build extension docker image
rm -fr $BASEDIR/docker/extensions

for extension_zipfile in `ls $BASEDIR/extensions`
do
  unzip $BASEDIR/extensions/$extension_zipfile -d $BASEDIR/docker/extensions
done

docker build $BASEDIR/docker -t $TAG


# 2. Generate Kubernetes deployment spec yaml

configmap_def=""
volume_mount_def=""

for extension_dir in `ls $BASEDIR/docker/extensions`
do
  configmap_def="$configmap_def --from-file=${extension_dir}-config.yml=$BASEDIR/docker/extensions/$extension_dir/config.yml"
  volume_mount_def="$volume_mount_def
        - key: ${extension_dir}-config.yml
          path: extensions/${extension_dir}/config.yml"
done

sed -e "s~##TAG##~$TAG~" $BASEDIR/template/ma-extension-base.yaml > $BASEDIR/deploy/ma-extension.yaml
echo "$volume_mount_def" >> $BASEDIR/deploy/ma-extension.yaml

if [ -f $BASEDIR/deploy/ma-extension-config.yaml ]; then
  cp -a $BASEDIR/deploy/ma-extension-config.yaml $BASEDIR/deploy/ma-extension-config.yaml.`date  "+%Y%m%d-%H%M%S"`
fi

kubectl create configmap -n appdynamics --dry-run=client ma-extension-config $configmap_def --output yaml > $BASEDIR/deploy/ma-extension-config.yaml

# If you are using old kubectl version, the --dry-run=client option may not be supported and get an error. Please use below instead.
# kubectl create configmap -n appdynamics --dry-run ma-extension-config $configmap_def --output yaml > $BASEDIR/deploy/ma-extension-config.yaml
