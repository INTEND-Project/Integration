# Install FILL

## Create namespece

```bash
kubectl create namespace fill
```

## Create secret for MongoDB

```bash
kubectl create secret generic mongo-secret --from-literal=MONGO_INITDB_ROOT_PASSWORD=<PASSWORD> -n fill
kubectl patch secret mongo-secret \
  -n fill \
  --type merge \
  -p '{"data":{"MONGO_URI":"<BASE64_VALUE>"}}'
```

## Install ArgoCD application from web interface
