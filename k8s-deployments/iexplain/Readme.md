# Install iExplain

## Create namespace

```bash
kubectl create ns iexplain
```

## Create secret for OPENAI_API_KEY

```bash
kubectl create secret generic openai-api-key --from-literal=OPENAI_API_KEY=<KEY> -n iexplain
```

## Install ArgoCD application from web interface
