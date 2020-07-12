# appdynamics-extension-k8s
Tool to easily deploy an AppDynamics extension to K8s

## How to use
1. Download your desired AppDynamics extensions from https://www.appdynamics.com/community/exchange/ . It should be a zip format file.
2. Place the downloaded zip file under extensions directory.
3. Run build.sh with the tag name of the extension docker image to create.
`./build.sh -t <your registry>/appdynamics/appdymamics-extensions:latest`
4. A Kubernetes deployment template file is generated as deploy/machine-agent-extension.yaml. Please edit the following before deploying. 
    - Edit the Controller properties
    - Edit the ##TAG## string to the extension docker image you used above.
    - Edit the extension configurations.
4. Create secret for controller access key.
`kubectl -n appdynamics create secret generic appd-secret --from-literal=appd-key="<Your access key>"`
5. Deploy the machine-agent-extension.yaml.
`kubectl -f deploy/machine-agent-extension.yaml`

