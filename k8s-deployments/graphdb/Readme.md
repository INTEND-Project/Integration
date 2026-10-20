# Install GraphDB

## Create namespace

```bash
kubectl create ns graphdb
```

## Create secret for license 

```bash
kubectl create secret generic graphdb-license --from-file graphdb.license=graphdb.license -n graphdb
```

## Install with Helm from CLI or by creating an ArgoCD application

```bash
helm repo add ontotext https://maven.ontotext.com/repository/helm-public/
helm install graphdb ontotext/graphdb -f values.yaml -n graphdb
```
