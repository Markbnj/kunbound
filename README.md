# kunbound

This repository demonstrates a kubernetes installation of the [unbound](http://www.unbound.net) DNSSEC compliant name resolver using docker, kubectl and helm. The repo contains a dockerfile, helm chart and makefile to assist with building the image (if you don't want to just pull it from my hub account) and installing the helm chart into your cluster.

## Requirements

* [docker](https://www.docker.com/)
* [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* [helm](https://helm.sh/)

In addition you'll obviously need a running kubernetes cluster. The yaml and scripts in kunbound were tested with kubectl 1.7.5 and helm 2.5.0 running against a cluster with master and nodes at 1.7.5 running in Google Container Engine. There are no GKE dependencies so this should work anywhere the above tools work.

## Repository structure

```
kunbound/
  etc/unbound/  - contains the default unbound.conf file for image testing
  kunbound/     - the root directory of the helm chart
  sbin/         - contains the startup script for unbound
  yaml/         - raw yaml for use if you can't/don't use helm
  Dockerfile    - build script for the unbound image
  Makefile      - a GNU makefile to make builds easy
```

## Installing the chart

A makefile is included to enable easily building and pushing the image (if needed), and installing the helm chart.

```
$ make
Build the kunbound image and install the helm chart

Usage: make TARGETS VARS

The following TARGETS are supportedL

image: build the docker image locally
test: test the docker image
no-cache: disable docker layer caching
build: runs image + test
rebuild: runs no-cache + image + test
push: push the image to a repo
release: install/upgrade the chart (dry-run)
apply: use before release to apply changes
all: runs build + push + release
help: display this help

The following VARS are supported

IMAGES_REPO: repository name to push image to
IMAGE_NAME: override default image name
IMAGE_TAG: override default image tag
TEST_HOST: override the default DNS test host
HELM_RELEASE: override the default release name
KUBE_CONTEXT: override the current kube context
VALUES: specify a values file to include
CLUSTER_IP4_CIDR: address range to allow
```

### To install the chart

```
$ make release VALUES=ZONES CLUSTER_IP4_CIDR=CIDR
```

This command will run helm against the chart templates and output the resulting yaml without updating anything in the cluster. To actually apply the resources in the cluster:

```
$ make apply release VALUES=ZONES CLUSTER_IP4_CIDR=CIDR
```

VALUES
- set to the path of the file which contains your forward zones and upstream resolver addresses.

CLUSTER_IP4_CIDR
- set to the cidr range of the pod network in your cluster to allow requests from pods, without this value the unbound container will only listen on localhost

Example zones file:

```
forwardZones:
- name: "fake.net"
  forwardHosts:
  - "fake1.host.net"
  - "fake2.host.net"
- name: "stillfake.net"
  forwardIps:
  - "10.10.10.10"
  - "10.11.10.10"
```

### To build and test the image locally

```
$ make build
```

### To build and test the image locally w/o the Docker layer cache

```
$ make rebuild
```

### To push the image to your repo (pushing it to mine won't work)

```
$ make push IMAGES_REPO=yourrepo
```

### Everything in one shot

```
$ make apply all IMAGES_REPO=yourrepo VALUES=zones CLUSTER_IP4_CIDER=cidr
```

## Update kube-dns to set the upstream

To get kube-dns to forward to a specific upstream for a private DNS zone we can edit its configmap in the kube-system namespace:

```
apiVersion: v1
data:
 stubDomains: |
 {“DNS_ZONE”: [“RESOLVER_IP”]}
kind: ConfigMap
metadata:
 labels:
 addonmanager.kubernetes.io/mode: EnsureExists
 name: kube-dns
 namespace: kube-system
```

Set the DNS_ZONE to the domain you want forwarded to unbound, and set RESOLVER_IP to the cluster IP address of the kunbound service that was created when the chart was installed. To find this address run `kubectl get svc | grep kunbound`. In order to update the configmap first run `kubectl get configmap kubedns -n kube-system -oyaml` and save the output to a file. Make the edits shown above to add the stubDomains section if it isn't there, and then use `kubectl apply -f file_path` to update the configmap in the cluster.
