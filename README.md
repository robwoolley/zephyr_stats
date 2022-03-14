# Zephyr Statistics

This is a Kubernetes configuration for provisioning a stack suitable for displaying build statistics about the Zephyr RTOS.

Development is being done with Windows 10 and Rancher Desktop (Docker mode).  However, the work should apply to any Kubernetes distribution.

# Setup

## Option A: Ubuntu 20.04 LTS with Minikube

Follow the [official installation instructions](https://minikube.sigs.k8s.io/docs/start/) to install the latest minikube release for *Linux* *x86-64* using the *stable* version via *binary download*.

### Kubernetes Dashboard
```
$ minikube dashboard
```

To access the Kubernetes dashboard from other machines on your network set up the proxy to listen on all interfaces and accept all hosts:
```
$ kubectl proxy --address='0.0.0.0' --accept-hosts='^*$'
Starting to serve on [::]:8001
```

You should now be able to access the dashboard at your machine's external IP address: http://192.168.10.17:8001/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/

### Remote Access

Run minikube tunnel to create external IPs for the services.
```
$ minikube tunnel
```

Verify that the EXTERNAL-IP column goes from (pending) to a valid IP.
```
$ kubectl get service
NAME         TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)          AGE
chronograf   LoadBalancer   10.99.89.126     10.99.89.126     8888:32418/TCP   73m
grafana      LoadBalancer   10.109.155.193   10.109.155.193   3000:31700/TCP   73m
influxdb     LoadBalancer   10.102.50.95     10.102.50.95     8086:31324/TCP   73m
kubernetes   ClusterIP      10.96.0.1        <none>           443/TCP          17h
```

To see all services that are running use --all with the services command:
```
$ minikube service --all
* service default/kubernetes has no node port
|-----------|------------|--------------|---------------------------|
| NAMESPACE |    NAME    | TARGET PORT  |            URL            |
|-----------|------------|--------------|---------------------------|
| default   | chronograf |         8888 | http://192.168.49.2:32418 |
| default   | grafana    |         3000 | http://192.168.49.2:31700 |
| default   | influxdb   |         8086 | http://192.168.49.2:31324 |
| default   | kubernetes | No node port |
|-----------|------------|--------------|---------------------------|
```

By design, Minikube only exposes Kubernetes services to the host machine.  In order to access the grafana service from a remote machine you must create an iptables rule to NAT packets into the minikube VM.

```
MINIKUBE_IP=$(minikube ip)
GRAFANA_PORT=$(minikube service --url grafana | cut -d: -f3)
echo "${MINIKUBE_IP} ${GRAFANA_PORT}"

sudo iptables -t nat -A DOCKER ! -i docker0 -p tcp -j DNAT --dport 3000 --to-destination "${MINIKUBE_IP}:${GRAFANA_PORT}"
```

This adds the last rule show below in the DOCKER chain.
```
$ sudo iptables -t nat -L DOCKER
Chain DOCKER (2 references)
target     prot opt source               destination
RETURN     all  --  anywhere             anywhere
RETURN     all  --  anywhere             anywhere
RETURN     all  --  anywhere             anywhere
DNAT       tcp  --  anywhere             localhost            tcp dpt:49153 to:192.168.49.2:32443
DNAT       tcp  --  anywhere             localhost            tcp dpt:49154 to:192.168.49.2:8443
DNAT       tcp  --  anywhere             localhost            tcp dpt:49155 to:192.168.49.2:5000
DNAT       tcp  --  anywhere             localhost            tcp dpt:49156 to:192.168.49.2:2376
DNAT       tcp  --  anywhere             localhost            tcp dpt:49157 to:192.168.49.2:22
DNAT       tcp  --  anywhere             anywhere             tcp dpt:3000 to:192.168.49.2:31700
```

You should now be able to access the Grafana dashboard here: http://192.168.10.17:3000/

Optionally, if you need to expose influxdb do the following:
```
INFLUXDB_PORT=$(minikube service --url influxdb | cut -d: -f3)

sudo iptables -t nat -A DOCKER ! -i docker0 -p tcp -j DNAT --dport 8086 --to-destination "${MINIKUBE_IP}:${INFLUXDB_PORT}"
```

<!--
Is this needed too?
sudo iptables -I DOCKER-USER 1 ! -i docker0 -o docker0 -p tcp -j ACCEPT -d $(minikube ip) --dport ${INFLUXDB_PORT}


## sudo iptables -t nat -A DOCKER ! -i docker0 -p tcp -j DNAT --dport 443 --to-destination $(minikube ip):3000
-->

## Option B: Rancher Destkop with WSL2

### Kubernetes Dashboard

You may want to have access to the Kubernetes dashboard with Rancher Desktop: 

The following Powershell commands are adapted from https://rancher.com/docs/k3s/latest/en/installation/kube-dashboard/ for a Windows 10 environment with Rancher Desktop.

```
$Response = Invoke-WebRequest -URI https://github.com/kubernetes/dashboard/releases/latest -MaximumRedirection 0 -ErrorAction Ignore
$Version = $Response.Headers.Location.split("/")[-1]
kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/${Version}/aio/deploy/recommended.yaml
```

### Create admin-user account

Download dashboard.admin-user.yml and dashboard.admin-user-role.yaml the "kube-dashboard" section of the k3s documentation listed above.

```
kubectl create -f dashboard.admin-user.yml -f dashboard.admin-user-role.yml
```

### Get the Bearer Token
kubectl -n kubernetes-dashboard describe secret 
kubectl -n kubernetes-dashboard describe secret admin-user-token-<k9-65r>

Copy the token value for logging into the dashboard listed below.
* http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/


## Managing Deployments

The Kubernetes resources are currently stored in separate manifest files.  The start.sh and stop.sh shell scripts have been provided to automate the process of applying and deleting the manifest files with kubectl.

NOTE: If Rancher Desktop is set to use Debian but your default WSL2 distro is Ubuntu, you may need to explicitly specify the WSL distro:
``` wsl -d Debian bash start.sh```

## Zephyr Test Results

See zephyr_test_results/README.md for details on how to deploy a pod to import the Zephyr Nightly Test Results into InfluxDB.

# Dashboards
* Grafana: http://localhost:3000/
* Chronograf: http://localhost:8888/
* Kubernetes dashboard: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

## To Do List
 * Set up private namespacing?

## References
1. [Monitor your infrastructure with InfluxDB and Grafana on Kubernetes](https://medium.com/starschema-blog/monitor-your-infrastructure-with-influxdb-and-grafana-on-kubernetes-a299a0afe3d2)
1. [How to spin up the TICK stack in a Kubernetes instance](https://www.influxdata.com/blog/how-to-spin-up-the-tick-stack-in-a-kubernetes-instance/)
1. [Install and Configure Grafana on Kubernetes](https://www.lisenet.com/2021/install-and-configure-grafana-on-kubernetes/)
1. [Kubernetes homelab by lisenet](https://github.com/lisenet/kubernetes-homelab)
1. [Minikube Documentation](https://minikube.sigs.k8s.io/)

## Appendix: Minikube Commands

Here are some useful minikube commands for troubleshooting problems.

```
$ minikube version
minikube version: v1.25.2
commit: 362d5fdc0a3dbee389b3d3f1034e8023e72bd3a7
```

Check the status of minikube
```
$ minikube status
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

Check minikube addons
```
$ minikube addons list
```


Get information about the cluster:
```
kubectl cluster-info
Kubernetes control plane is running at https://192.168.49.2:8443
CoreDNS is running at https://192.168.49.2:8443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

Check the kubectl and minikube kubectl versions
```
$ kubectl version -o yaml
$ minikube kubectl -- version -o yaml
```
