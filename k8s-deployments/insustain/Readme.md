# InSustain on Integration

This lightweight Helm application deploys the InSustain backend and dashboard
using existing private GHCR packages associated with `INTEND-Project/InSustain`.
**Integration does not build or republish these images.** The producer release
pipeline owns images; Integration owns reviewed deployment configuration; the
administrator owns cluster provisioning and ArgoCD reconciliation.

Stage one covers sustainability intents, energy reports, and the dashboard.
Prediction/training and MLflow provisioning are deferred. Existing dashboard ML
controls remain visible but unsupported; the automatic training scheduler is
disabled. The `mlflowUrl` compatibility value is not a feature gate and does not
disable ML API routes. Do not use ML controls as part of stage-one acceptance.

## Published release and validation status

Authenticated GitHub Packages metadata verified on 2026-11-23 confirms both
private packages have release `v0.1.11`, published 2026-11-20. The chart pins:

| Image repository | Digest |
|---|---|
| `ghcr.io/intend-project/insustain-backend` | `sha256:a3573f585834c7be5d184cf2ac7523ae7b38f2c253377f9a59a60f141541cde4` |
| `ghcr.io/intend-project/insustain-frontend` | `sha256:69afe73c3d0b9f57e075d10e529e0a0fa66b4e30f860d145eeb2aa11cb345f67` |

Package metadata is not proof of target architecture compatibility, successful
pulls from the cluster, or runtime behavior. Those checks are still outstanding.
Helm lint/render tests validate configuration without building or pulling images.

Chart delivery and successful integration are separate milestones. Missing
energy metrics do not block reviewing the chart, but do block accepting energy
reports. Never interpret absent metrics as measured zero energy or describe
modelled estimates as direct hardware measurements.

## Administrator prerequisites

Before reconciliation, confirm/provision:

1. The application namespace (recommended release name and namespace: `insustain`).
2. A namespace-local `kubernetes.io/dockerconfigjson` pull Secret with read access
   to **both** private GHCR packages. Use a managed read-only credential, not the
   producer's writer token. Set `imagePullSecrets.name` to the Secret's name.
3. A dedicated database/user on shared MongoDB. Confirm host, database,
   `authSource`, optional mechanism, and username/password Secret keys. The Secret
   must be in the application namespace, even when MongoDB is in another namespace.
   Confirm persistence, backups, and network access with the database owner.
4. The shared Prometheus URL, monitored workload namespace, and label selector.
   Confirm the energy provider, metric names/labels, supported calculations, and
   data provenance against the pinned backend. Prometheus alone does not supply
   energy measurements; energy exporters remain infrastructure-owned.
5. Pod-discovery permissions in the monitored namespaces. If using
   `rbac.targetNamespaces`, those namespaces must exist and the ArgoCD deployer
   must be allowed to create Roles/RoleBindings there.
6. Image architecture compatibility and backend startup/core functionality without
   an MLflow service. Resolve any necessary producer fix through a new published
   release, not an Integration build.
7. ArgoCD registration/reconciliation using the administrator's usual convention.
8. Before public exposure: approved hostname, TLS, certificate issuer, and access
   controls. This chart does not implement authentication. Leave Ingress disabled
   until the cluster's authentication/access policy is applied.

Secrets are provisioned through the administrator's existing Secret/Vault process.
This application commits neither credentials nor Secret manifests. Do not place
tokens/passwords in a values file committed to git.

## Example administrator values

Replace these neutral placeholders with confirmed environment settings. Service
addresses in chart defaults are proposals, not verified live endpoints.

```yaml
imagePullSecrets:
  name: insustain-ghcr-reader

backend:
  prometheusUrl: http://prometheus.monitoring.svc.cluster.local:9090
  namespaceName: integration-workloads
  podLabelSelector: app
  mongo:
    url: mongodb.mongodb.svc.cluster.local:27017
    database: insustain
    authSource: insustain
    usernameSecret:
      name: insustain-mongodb-auth
      key: username
    passwordSecret:
      name: insustain-mongodb-auth
      key: password

rbac:
  create: true
  clusterWide: false
  targetNamespaces:
    - integration-workloads
```

By default, the chart creates a backend ServiceAccount and a pod-reader Role and
RoleBinding only in the release namespace (`get`, `list`, `watch` on `pods`).
`rbac.targetNamespaces` adds the same scoped permissions in approved namespaces;
it does not deploy workloads or create namespaces. Set `backend.namespaceName`
to the intended monitored namespace as well: permission grants do not change the
backend's discovery configuration. This chart configures one discovery namespace;
additional grants do not imply automatic multi-namespace discovery.

Unrestricted cluster-wide pod discovery is an explicit `rbac.clusterWide: true`
opt-in, mutually exclusive with `targetNamespaces`. No `metrics.k8s.io` grant is
required. To use an administrator-managed account and permissions instead:

```yaml
rbac:
  create: false
  clusterWide: false
  targetNamespaces: []
serviceAccount:
  name: existing-insustain-pod-reader
```

That account and all its permission grants must already exist. Scope settings
must be cleared when `rbac.create: false`; otherwise rendering fails rather than
silently dropping requested grants. The account must be in the release namespace.
To name a chart-managed
account, set `serviceAccount.name` while keeping `rbac.create: true`.

### Optional shared GraphDB publishing

TMF reports can be returned by InSustain without GraphDB publishing. Enable it
only when the shared repository/graph, connectivity, and the pinned image's
supported access requirements are confirmed. The chart does not add GraphDB
authentication support or deploy a database:

```yaml
backend:
  graphdb:
    enabled: true
    url: http://graphdb.graphdb.svc.cluster.local:7200
    repository: intents_and_intent_reports
    graph: urn:integration:reports
```

An empty `graph` uses the backend's default-graph behavior. GraphDB failures need
separate verification; generating a report is not proof observations were
published. InSustain publishes observations, not intent lifecycle transitions.

### Frontend routing

The frontend Service listens on port 3000 and proxies APIs to the backend Service
(port 8089 by default). Its default upstream follows `backend.service.port`;
`frontend.backendUrl` is an optional explicit override. The container's backend
port remains 8089 when changing the Service port.

Only enable public routing after access controls are in place:

```yaml
ingress:
  enabled: true
  className: traefik
  host: insustain.example.org
  tlsSecretName: insustain-tls
  clusterIssuer: approved-cluster-issuer
```

Leave `clusterIssuer` empty when certificates are managed outside cert-manager.
The backend remains a ClusterIP Service, not a public Ingress. Approved consumers
can use `http://insustain-backend.insustain.svc.cluster.local:8089` and TMF API
base path `/tmf-api/intentManagement/v5`. Adjust namespace/port when configured
differently and coordinate consumer routing with its owner.

## ArgoCD handoff

Register the application in the administrator's existing ArgoCD process with:

- Repository: `https://github.com/INTEND-Project/Integration`
- Path: `k8s-deployments/insustain/application`
- Revision: the reviewed branch/commit, then the approved main revision
- Helm release name: `insustain`
- Destination: approved cluster and application namespace
- Values: confirmed endpoints, Secret references, RBAC scope, optional GraphDB/Ingress

No ArgoCD Application object is included because project, destination, values
delivery, and sync policy are administrator-owned. No CI job needs cluster or
ArgoCD credentials. Ensure ArgoCD permits any explicitly scoped cross-namespace
RBAC resources before syncing.

## Chart validation

From the Integration repository root:

```bash
helm lint k8s-deployments/insustain/application
python3 -m unittest discover -s k8s-deployments/insustain/tests -v
helm template insustain k8s-deployments/insustain/application --namespace insustain
```

Use `-f <administrator-values.yaml>` to inspect environment overrides before
reconciliation. Schema/render checks reject invalid image digests and inconsistent
settings. The chart-only GitHub workflow runs lint and regression tests, without
Docker builds, package-write permissions, private pulls, or deployments.

## Runtime integration checklist

After administrator rollout, verify:

- Both digest-pinned images pull on the target architecture; pods start, the
  frontend `/healthz` responds, and the dashboard connects to the backend.
  Frontend process probes do not prove backend health; backend probes are deferred
  until a suitable endpoint is verified against the image.
- Create/list/retrieve/delete a representative sustainability intent. Generate
  and retrieve an energy report with correct workload mapping, units, provenance,
  and missing-data behavior. Suitable Prometheus energy series are mandatory for
  accepting this check. Missing data is a blocked check, not a zero measurement.
- Application state survives a backend pod restart via shared MongoDB.
- Pod discovery succeeds in approved namespaces and access is denied elsewhere.
- If publishing is enabled, observations reach the intended GraphDB repository/
  graph and publication failures are observable.
- If Ingress is enabled, TLS and the agreed access controls work.
- Do not assess prediction/training as supported stage-one functionality.

## Release updates and rollback

Update both image digests through a reviewed Integration change using the exact
producer-published artifacts; never use floating tags. The human-readable release
is documented here and in `Chart.yaml`. Roll back by restoring the previous
reviewed image pair/configuration, subject to database compatibility review.
Integration never rebuilds or retags the images.
