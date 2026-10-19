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
  --patch-file argocd-repo-server-patch.yaml \
  --dry-run=server -o yaml > argocd-repo-server-preview.yaml
```

## Apply patch if validation is ok

```bash
kubectl patch deployment argocd-repo-server \
  -n argocd \
  --type strategic \
  --patch-file argocd-repo-server-patch.yaml
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
