# Hashicorp vault secrets operator

## Howto

1. Create namespace and service account

```bash
kubectl create ns app
kubectl create serviceaccount vso-app -n app
```

2. Add a secret entry

```bash
vault kv put secret/myapp \
  username="myuser" \
  password="mypassword123"
```

3. Create policy for the secret

```bash
vault policy write myapp-read - <<'EOF'
path "secret/data/myapp" {
  capabilities = ["read"]
}
EOF
```

4. Create Kubernetes auth role

```bash
vault write auth/kubernetes/role/myapp-role \
  bound_service_account_names=vso-app \
  bound_service_account_namespaces=app \
  audience=vault \
  token_policies=myapp-read \
  ttl=1h
```

5. Create VaultAuth and VaultStaticSecret applying:

```yaml
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultAuth
metadata:
  name: myapp-auth
  namespace: app
spec:
  method: kubernetes
  mount: kubernetes
  kubernetes:
    role: myapp-role
    serviceAccount: vso-app
    audiences:
      - vault
---
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: myapp-secret
  namespace: app
spec:
  type: kv-v2
  mount: secret
  path: myapp
  vaultAuthRef: myapp-auth
  destination:
    name: myapp-k8s-secret
    create: true
  refreshAfter: 60s
```