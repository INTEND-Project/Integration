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
## Create secret for OpenAI

```bash
kubectl create secret generic openai-secret --from-literal=OPENAI_API_KEY=<KEY> -n fill
```

## Install ArgoCD application from web interface
