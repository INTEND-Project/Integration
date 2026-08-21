# Install FILL

## Create namespece

```bash
kubectl create namespace fill
```

## Create secret for MongoDB

MongoDB was deployed as standalone in namespace mongodb, database "fill" and user "fill" have been created. 
MONGO_URI will have this format (password is the password set for the user fill):
mongodb://fill:password@mongodb.mongodb.svc.cluster.local:27017/fill?authSource=fill

```bash
kubectl create secret generic mongo-secret --from-literal=MONGO_URI=<MONGO_URI> -n fill

```
## Create secret for OpenAI

```bash
kubectl create secret generic openai-secret --from-literal=OPENAI_API_KEY=<KEY> -n fill
```

## Install ArgoCD application from web interface
