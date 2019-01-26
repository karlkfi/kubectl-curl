# kubectl-curl

kubectl plugin to curl the Kubernetes API with your current KUBECONFIG context

## Install

```
sudo cp kubectl-curl.sh /usr/local/bin/kubectl-curl
```

## Usage

Pass the path as the 1st argument to `kubectl curl`.

```
$ kubectl curl api
{
  "kind": "APIVersions",
  "versions": [
    "v1"
  ],
  "serverAddressByClientCIDRs": [
    {
      "clientCIDR": "0.0.0.0/0",
      "serverAddress": "10.212.0.2:443"
    }
  ]
}
```

Subsequent arguments are passed directly to `curl`.

## Evict

The `kubectl evict` command can be used to evict a pod by name (after checking the pod disruption budget).
See [The Eviction API](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/#the-eviction-api).

### Evict Install

```
sudo cp kubectl-curl.sh /usr/local/bin/kubectl-curl
```

### Evict Usage

The current context's namespace is used (or default), unless another is specified via command line option `-n` or `--namespace`.

```
$ kubectl evict inara -n serenity
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {

  },
  "status": "Success",
  "code": 201
}
```
