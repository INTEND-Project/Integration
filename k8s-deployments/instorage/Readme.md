# Install inStorage

## Create namespace

```bash
kubectl create ns instorage
```

## Create secret for Neo4J

```bash
kubectl -n instorage create secret generic neo4j-auth \
  --from-literal=KNOWLEDGE_GRAPH_NEO4J_USERNAME='<username>' \
  --from-literal=KNOWLEDGE_GRAPH_NEO4J_PASSWORD='neo4j/<password>'
```

## Create ArgoCD application from Git repository
