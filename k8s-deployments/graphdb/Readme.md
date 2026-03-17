# Install GraphDB

## Create secret for license 

```bash
kubectl create secret generic graphdb-license --from-file graphdb.license=graphdb.license
```

## Install with Helm from CLI

```bash
helm repo add ontotext https://maven.ontotext.com/repository/helm-public/
helm install graphdb ontotext/graphdb -f values.yaml
```
