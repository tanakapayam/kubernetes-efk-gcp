# Kubernetes EFK Stack for GCP

> The EFK stack for kubernetes clusters.

## Installation

To deploy these configs to an existing cluster, run `kubectl apply -f ./configs --recursive`.

After the elasticsearch cluster is finally up (ETA 2 minutes or so), delete all of the existing indexes so that the mapping template applies to the new index.

ssh into one of the elastic search pods and run:

```
curl -X DELETE localhost:9200/_all
```

## Kibana

Note that if you're creating a kibana instance, it will need to bundle all of its resources. This can take up to 7 minutes based on how many cpu requests we've allotted the pod. So go grab a coffee or something and come back once `kubectl -n kube-system logs $pod -f` prints something besides `Optimzing and caching bundles...`

Everything is running in the kube-system namespace.

The Kibana front end will be exposed as a service to the web and available at port `80`. If you want to lock down your Kibana front end to a specific IP range simply add a block like below with your office IP ranges or /32 address. This stanza goes in the service spec at the same level as `type: LoadBalancer`

     loadBalancerSourceRanges:
    - 10.0.0.8/8
    - 35.22.22.22/32

## Notes

When we reference "elasticsearch nodes", we technically mean "elasticsearch pods" in the kubernetes dialect, but distributed software like elasticsearch has standardized on calling each instance a node as well. So we're going to call both things nodes and rely on context to differentiate.

## How it Works

Kubernetes nodes put all docker logs into `/var/lib/docker/containers`. We run a `fluentd-logging` container on each node, which has `/var/lib/docker/containers` mounted and watches the files for changes. When it detects a change, it ships it off to our `elasticsearch-logging` pod.

Finally, we can query those `elasticsearch-logging` logs with `kibana-logging`.

## Per-Node `fluentd` containers.

We use a [DaemonSet](http://kubernetes.io/docs/admin/daemons/) to guarantee that each node receives a `fluentd` pod.

This `fluentd` is configured to parse the logs it encounters using various rules defined in `td-agent.conf`.

## Storage

We provide dynamic persistent storage to the elasticsearch nodes by creating them as a `StatefulSet` with a `persistentVolumeClaimTemplate` field. This field defines a template for a `PVC`, which dynamically creates `GCE` volumes based on a `StorageClass`. In this case we allocate 100Gb gp2 volumes per-elasticsearch-node and attach them to the appropriate kubernetes nodes. This is where the indicies will write to on each elasticsearch node.

## Networking

The only special situation with networking is the use of two services for elasticsearch, `elasticsearch-logging` and `elasticsearch-transport`. The (headless) `elasticsearch-transport` service is used by the [elasticsearch-cloud-kubernetes](https://github.com/fabric8io/elasticsearch-cloud-kubernetes) plugin to discover peers. The `elasticsearch-logging` service is cluster-public and allows clients like Kibana (and you!) to connect to the elasticsearch API.

## Elasticsearch Pod

The elasticsearch pod is the most complicated of the definitions. It contains two containers: one elasticsearch instance, and a `curator` sidecar that uses cron to rotate indices once they're older than `DAYS` days old (default 7 days).

The `elasticsearch.yml` also requires a special configuration of the kuberenetes nodes themselves to be able to run the latest versions of elasticsearch. 

    pod.beta.kubernetes.io/init-containers: '[
      {
      "name": "sysctl",
        "image": "busybox",
        "imagePullPolicy": "IfNotPresent",
        "command": ["sysctl", "-w", "vm.max_map_count=262144"],
        "securityContext": {
          "privileged": true
        }
      }
    ]'
This section utilizes an init-container to run the command `sysctl -w vm.max_map_count=262144` on the kubernetes nodes themselves, which is required by Elasticsearch in versions > 4.0.

Elasticsearch is configured to use /data as `{path.data}`, which is where the GCE volume from above is mounted. The wrapper startup script `run.sh` does two things:

1. It chowns the `/data` directory. As of Elasticsearch version 5.x you can no longer run the application as root, so we need to chown this directory before run time after its mounted.
2. It `PUT`s the index template to the ES API. ES no longer support reading templates from disk, so we've resorted to this hack to add the template to the indices.
  - One thing to watch out for is that the template won't take effect on the current indices, so we'll have to delete them on the first (and only the first) deployment (to be more specific, only when a new, fresh GCE volume is used).
  - To do so, exec into one of the `elasticsearch-logging` pods and run `curl -X DELETE localhost:9200/_all` to delete all of the existing indices.

## Special Thanks

This repository is a heavily modified version of https://github.com/Skillshare/kubernetes-efk which is designed for aws.

## Contributing

If you'd like to improve on this repository or have suggestions, raise a PR or issue. This repository is currently being actively improved and tuned for the latest GKE/GCP updates.