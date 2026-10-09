# Install Neo4J

## Create namespace

```bash
kubectl create ns neo4j
```

## Create secret for password

```bash
kubectl -n neo4j create secret generic neo4j-auth \
  --from-literal=NEO4J_AUTH='neo4j/<password>'
```

## Create ArgoCD application from Git repository
