# Install ArgoCD vault plugin

## Apply config map

```bash
kubectl apply -n argocd -f cmp-plugin.yaml
```

## Validate patch 

```bash
kubectl patch deployment argocd-repo-server \
  -n argocd \
  --type strategic \
  --patch-file argocd-repo-server-avp-patch.yaml \
  --dry-run=server -o yaml > argocd-repo-server-preview.yaml
```

## Apply patch if validation is ok

```bash
kubectl patch deployment argocd-repo-server \
  -n argocd \
  --type strategic \
  --patch-file argocd-repo-server-avp-patch.yaml
```

## Verify installation

```bash
kubectl -n argocd rollout status deployment/argocd-repo-server \
  --timeout=300s

kubectl -n argocd get pods

kubectl -n argocd get deployment argocd-repo-server \
  -o jsonpath='{.spec.template.spec.containers[*].name}{"\n"}'
```

## Revert if problems

```bash
kubectl -n argocd rollout history deployment/argocd-repo-server

kubectl -n argocd rollout undo deployment/argocd-repo-server --to-revision=1

kubectl -n argocd rollout status deployment/argocd-repo-server
```

# Configure Kubernetes auth using "argocd-repo-server" service account from ArgoCD

- Create policy

```bash
vault policy write argocd-avp - <<'EOF'
path "secret/data/*" {
  capabilities = ["read"]
}

path "secret/metadata" {
  capabilities = ["read", "list"]
}

path "secret/metadata/*" {
  capabilities = ["read", "list"]
}
EOF
```

- Create role

```bash
vault write auth/kubernetes/role/argocd \
  bound_service_account_names=argocd-repo-server \
  bound_service_account_namespaces=argocd \
  audience="https://kubernetes.default.svc.cluster.local" \
  policies=argocd-avp \
  ttl=1h
```

