# Install Hashicorp vault

## Create vault namespace

```bash
kubectl create ns vault
```

## Create ArgoCD application using this Helm chart and set vault as namespace

## Initialize vault

```bash
kubectl exec -n vault vault-0 -- vault operator init \
  -key-shares=3 \
  -key-threshold=2
```
  
## Unseal vault using at least 2 different keys

```bash
kubectl exec -it -n vault vault-0 -- vault operator unseal
```

## Howto

1. Log in to Vault

```bash
kubectl exec -it -n vault vault-0 -- sh
vault login
```

2. Enable the KV secrets engine

```bash
vault secrets list
vault secrets enable -path=secret kv-v2
```

3. Add a secret entry

```bash
vault kv put secret/myapp \
  username="myuser" \
  password="mypassword123"
```

4. Read the secret

```bash
vault kv get secret/myapp
vault kv get -field=password secret/myapp
```

5. Update an entry

```bash
vault kv put secret/myapp \
  username="myuser" \
  password="newpassword456"
```

6. Delete an entry

Latest version:

```bash
vault kv delete secret/myapp
```

Permanent:

```bash
vault kv metadata delete secret/myapp
```