# Install 5g4data

## Create namespece

```bash
kubectl create namespace 5g4data
```

## Create secret for Postgresql

Postgresql was deployed as standalone in namespace postgres, database "a2a_registry" and user "a2a_user" have been created. 
DATABASE_URL will have this format (password is the password set for the user a2a_user):
postgresql://a2a_user:password@postgres.postgres.svc.cluster.local:5432/a2a_registry

```bash
kubectl create secret generic postgres-secret --from-literal=DATABASE_URL=<DATABASE_URL> -n 5g4data

```

## Install ArgoCD application from web interface
