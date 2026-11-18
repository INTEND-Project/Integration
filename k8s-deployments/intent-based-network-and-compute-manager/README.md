# Intent Manager on Kubernetes (Helm chart), InNet & InOrch

This folder is the chart of `intent-manager-deployment` (`k8s/`, branch `dev`, commit `dc65bb0`) reduced to what
InNet and InOrch need. Removed: the `mdo-tmf-agent` (TMF641), the publication through the KU Gateway
(`HTTPRoute`, `httpRoutes`, `values-ku-vcluster.example.yaml`), the TMF633 catalogue parameters of the
translator, CL coordination between CLGs (Federation Managers), the standalone `test/nsmf-mock.yaml`, the compose
alias Services. Added: `global.namePrefix`, the prefix of the application components (default
`innet-and-inorch`; data services and mocks keep their names, see [Service names](#service-names)).

**Status:** installed and running on a k3s cluster (Kubernetes 1.35) with all three agents: a networking-only
intent written in natural language went through translation, the LCM, operation-management, Kafka and the
NSMF agent to a slice on an NSMF mock (PROVISIONED in about 20 s), and its deletion terminated the slice. Not
yet exercised: a deployment intent (SOCCER), a real NSMF, the `knowledge-graph-bootstrap` Job. See [What is verified](#what-is-verified-and-what-is-not-yet).

The chart [`intent-manager/`](intent-manager/) deploys the components of `intent-manager-multirepo` **and the
data services they need** (PostgreSQL, Fuseki, Qdrant, Kafka with ZooKeeper), with the same images, variables
and defaults as `intend/docker-compose-v3.yaml`. The systems the agents call (NSMF, SOCCER) and the CLG
are external and configured in `values.yaml` under `external`, or replaced by mocks with the profile
[`values-innet-inorch-mocks.yaml`](intent-manager/values-innet-inorch-mocks.yaml) (see
[Mock profile](#mock-profile-innet--inorch)).

**One chart for InNet and InOrch.** The same release serves both INTEND intent managers:

| Part | InNet (network intents, slices) | InOrch (deployment intents) |
|---|---|---|
| `intent-lcm` (LCM + translator), `operation-management`, GUI, ontology-init, data services | yes | yes |
| `3gpp-nsmf-agent` -> NSMF (`external.nsmf`) | yes | - |
| `soccer-agent` -> SOCCER (`external.soccer`) | - | yes |
| closed loops on the CLG (`external.clg`) | slice closed loop | application closed loop |

Only InNet: `--set agents.soccer.enabled=false`; only InOrch: `--set agents.nsmf.enabled=false` (with the mock
profile, also `mocks.soccer.enabled=false` / `mocks.nsmf.enabled=false`).

## What the chart contains

| Compose v3 service | Repository | In the chart |
|---|---|---|
| `intent-lcm` | `intent-lcm` | Deployment + Service `intent-lcm` (LCM 8080, translator 8082) |
| `fuseki-intent-dataset-init` | `ontology-init` | init container of `intent-lcm`: the LCM starts only after the ontologies are loaded |
| `operation-management` | `operation-management` | Deployment + Service `operation-management` |
| `intent-manager-gui` | `intent-manager-gui` | Deployment + Service `intent-manager-gui` (8080) |
| `nsmf-plugin` | `plugins/3gpp-nsmf-agent` | Deployment `3gpp-nsmf-agent` (`agents.nsmf.enabled`, default on) |
| `soccer-agent` | `plugins/soccer-agent` | Deployment `soccer-agent` (`agents.soccer.enabled`, default on) |
| `qdrant-rag-bootstrap` (profile) | `knowledge-graph-bootstrap` | hook Job `knowledge-graph-bootstrap` (`knowledgeGraphBootstrap.enabled`, default off) |
| `intent-manager-postgres` | - | StatefulSet + PVC, Service `intent-manager-postgres` (`postgres.enabled`) |
| `fuseki` | - | StatefulSet + PVC, Service `fuseki` (`fuseki.enabled`) |
| `qdrant` | - | StatefulSet + PVC, Service `qdrant` (`qdrant.enabled`) |
| `zookeeper`, `kafka` | - | StatefulSets without volumes, as in compose (`kafka.enabled`) |
| `nsmf-mock`, `soccer-mock`, `clg-mock` (compose v3-mock) | `nsmf-mock`, `soccer-mock`, `clg-mock` | Deployment + Service each (`mocks.<name>.enabled`, default off); ConfigMap `clg-mock-application-profile` |

`tmf921-libraries` and `plugin-interfaces` are libraries: nothing to deploy.

## Service names

The application components are named `<global.namePrefix>-<compose name>`; the tables in this README give the
compose name. The prefix is `innet-and-inorch` by default, so the release creates `innet-and-inorch-intent-lcm`,
`innet-and-inorch-operation-management`, `innet-and-inorch-intent-manager-gui`, `innet-and-inorch-3gpp-nsmf-agent`,
`innet-and-inorch-soccer-agent` and the Job `innet-and-inorch-knowledge-graph-bootstrap`.
`--set global.namePrefix=""` gives the plain compose names.

Without the prefix, with the compose names: the data services (StatefulSets and their Services
`intent-manager-postgres`, `fuseki`, `qdrant`, `kafka`, `zookeeper`), the mocks (`nsmf-mock`, `soccer-mock`,
`clg-mock` and the ConfigMap `clg-mock-application-profile`) and the Secret `<release>-secrets`.

- The prefix: lower-case letters, digits and `-`, starting with a letter, at most 30 characters; anything else
  stops the render with a message. Kubernetes names allow no capitals nor `&`, hence `innet-and-inorch` for
  "InNet&InOrch".
- Every address a component uses to reach another one is computed from the same names: LCM, translator,
  operation-management, GUI upstreams, the `href` of the intents (`INSTANCE_PREFIX`). An empty
  `external.<x>.host` (or mock URL) means the data service (or mock) of this release.
- The compose alias Services (`intent-lcm-backend`, `intentlcm`, `intenttranslator`, `operationmanagement`,
  `postgres`) are gone: they only served the images' own defaults, which the chart always overrides.
- The label `app.kubernetes.io/name` stays the compose name. Data services and mocks are not prefixed, so it is
  still **one release per namespace**.
- Changing the prefix of an installed release replaces only the application Deployments and Services; the data
  (StatefulSets and PVCs) stays.

In the commands below, `<p>` is the prefix with its dash (`innet-and-inorch-` by default); data services and
mocks have no `<p>`.

## What must exist before installing

| Need | Value |
|---|---|
| A StorageClass for the three PVCs (2 GiB each by default) | `<service>.storage.storageClass`, `""` = the cluster default |
| Pull access to `rd-registry.nextworks.it:443` (and Docker Hub for postgres, fuseki, qdrant, zookeeper, busybox) | `global.imagePullSecrets` |
| An OpenAI API key: **the translator does not start without one** (`OpenAI API key must be set`), and then the whole `intent-lcm` pod restarts | `secrets.openaiApiKey` |
| NSMF, SOCCER, CLG, only for the agents and closed loops that use them | `external.nsmf`, `external.soccer`, `external.clg` |

About 3 GiB of memory for the whole release at rest (Fuseki ~1 GiB, intent-lcm ~0.75 GiB, Kafka and
operation-management ~0.4 GiB each). `global.nodeSelector` pins every pod to chosen nodes, e.g. one with free
disk. To use a data service deployed elsewhere: `<service>.enabled=false` and point `external.<service>` to it.
A host name that resolves only through a fixed IP (compose `extra_hosts`) goes in `global.hostAliases`.

## Credentials

Never commit them. Either:
- copy [`values.secret.example.yaml`](intent-manager/values.secret.example.yaml) to `values.secret.yaml` in the
  same folder (ignored by git), fill it in and pass it with `-f`; the chart creates the Secret
  `<release>-secrets`; or
- create the Secret yourself and set `secrets.existingSecret`:
  ```bash
  kubectl -n <ns> create secret generic intent-manager-secrets \
    --from-literal=POSTGRES_PASSWORD=... --from-literal=FUSEKI_ADMIN_PASSWORD=... \
    --from-literal=OPENAI_API_KEY=...
  ```

Registry pull secret, if the cluster has no access yet:
```bash
kubectl -n <ns> create secret docker-registry rd-registry \
  --docker-server=rd-registry.nextworks.it:443 --docker-username=... --docker-password=...
```
then `--set 'global.imagePullSecrets[0].name=rd-registry'`.

## Commands

From this folder:
```bash
helm lint intent-manager -f intent-manager/values.secret.yaml
helm template im intent-manager -n <ns> -f intent-manager/values.secret.yaml > /tmp/im.yaml   # review the result

helm upgrade --install im intent-manager -n <ns> --create-namespace -f intent-manager/values.secret.yaml
kubectl -n <ns> get pods -w            # data services first; intent-lcm: wait-*, ontology-init, then Running (~3 min)
kubectl -n <ns> rollout restart deployment/<p>intent-lcm   # after changing a secret: pods do not reload it

helm uninstall im -n <ns>              # the PVCs (PostgreSQL, Fuseki, Qdrant data) stay
kubectl delete namespace <ns>          # removes everything, data included
```
Always upgrade with the same `-f` files (and `--set`) as the install. Do not use `--reuse-values`: it ignores
the defaults that a newer chart adds, which then render as empty values.

The GUI is served at `/intent-manager-gui/` and proxies the calls to intent-lcm, the translator,
operation-management and Fuseki itself (`*_UPSTREAM`), so it is the only component that needs to be
reachable from outside. Its image has `resolver 127.0.0.11` (the Docker DNS) in its nginx template: on
Kubernetes the chart replaces that line with the cluster DNS through an init container (`gui.nginxResolver`,
default `auto`) and passes full Service names as upstreams. Once the image makes the resolver configurable,
set `gui.nginxResolver: ""`.

To reach it from your machine (or publish `intent-manager-gui:8080` with your own Ingress):
```bash
kubectl -n <ns> port-forward svc/<p>intent-manager-gui 4202:8080    # then http://localhost:4202/intent-manager-gui/
```

## Mock profile (InNet & InOrch)

[`values-innet-inorch-mocks.yaml`](intent-manager/values-innet-inorch-mocks.yaml) runs both kinds of intent end
to end with no real element, as `intend/docker-compose-v3-mock.yaml` does with compose:
```bash
helm upgrade --install im intent-manager -n intent-manager --create-namespace \
  -f intent-manager/values-innet-inorch-mocks.yaml -f intent-manager/values.secret.yaml
```

| Mock | Replaces | Used by | Service |
|---|---|---|---|
| `nsmf-mock` | NSMF; already knows `nst-ec21-001`, no onboarding | InNet, `3gpp-nsmf-agent` | `nsmf-mock:9091` |
| `soccer-mock` | SOCCER; accepts `aaaaaaaa-…`, `bbbbbbbb-…` and `EXTRA_DESCRIPTOR_IDS` (default the vLLM suite `c6fbdc7d-…`) | InOrch, `soccer-agent` | `soccer-mock:9090` |
| `clg-mock` | the CLG; creates and terminates closed loops, keeps their events, fakes the Kubernetes API for pod logs | both, `intent-lcm` | `clg-mock:8080` |

The profile also:
- sets `CL_GOVERNANCE_DRIVER=rest`, so closed loops are really created on clg-mock: the slice one
  (`82399198-…`) for InNet, the application one (`1035f45d-…`, profile in the ConfigMap
  `clg-mock-application-profile`, mounted at `/app/mock/`) for an InOrch intent that bounds `compute_latency`;
- empties `external.nsmf.baseUrl`, `external.soccer.baseUrl` and `external.clg.governanceUrl`, so the chart
  points them at the mocks of the release; no address of a real system is left.

Try it as in [What is verified](#what-is-verified-and-what-is-not-yet): `GET
http://<p>intent-lcm:8082/agentic/stream?message=<text>&conversationId=<id>`, then the message `CREATE_INTENT`.
One network prompt (InNet) and one deployment prompt with a compute-latency objective (InOrch). Look at the
mocks with `kubectl port-forward`: `svc/clg-mock 18090:8080` then `curl localhost:18090/__mock/state`;
`svc/nsmf-mock 19080:9091` for the NSIs.

The mocks keep their state in memory: restarting their pods forgets every NSI, service instance and closed loop.

Images: the tag `intend-munich-2026` (`global.imageTag` and the three `mocks.<x>.image.tag`), pushed on
2026-11-17 on the digests of `master` of that day, the set tested together on .139. What they give:
- slices and deployments up to `PROVISIONED`, and `DELETE` terminates them;
- closed loops created and terminated on clg-mock. this intent-lcm does not subscribe to their events, so the
  intent report gets no observation nor log from them (images of `feature/evolved-intent-reports` and
  `feature/cl-reports` do: uncomment their variables in the profile);
- clg-mock (built 2026-11-17 from `ea1e144`) emulates the 5G slice and vLLM closed loops with their real
  log lines and events; the closed-loop reports (`feature/cl-reports`) are not in it yet.

## Choose the agents

Each agent is deployed only when its flag is `true`:
```yaml
agents:
  nsmf:   {enabled: true}     # 3gpp-nsmf-agent
  soccer: {enabled: true}     # soccer-agent
```
e.g. `--set agents.soccer.enabled=false` for InNet only.

## Configure the components

`values.yaml` lists **every** environment variable each component reads, in its `env` block
(`intentLcm.env`, `intentLcm.translatorEnv`, `operationManagement.env`, `gui.env`, `agents.<name>.env`,
`ontologyInit.env`, `knowledgeGraphBootstrap.env`), each with the code default in a comment:
- `~` (null): not set, the application uses its own default; where the comment says `chart: ...`, the chart
  sets the value it computes from `external`, the topics or the Secret;
- a value: set as written. Out of the box these are the values compose v3 sets.

A value in the `env` block always wins, also over the computed ones. Examples:
```bash
--set intentLcm.env.LOG_LEVEL_IT_NEXTWORKS=INFO
--set intentLcm.translatorEnv.SPRING_AI_OPENAI_CHAT_MODEL=gpt-4o-mini   # becomes INTERPRETER_SPRING_AI_OPENAI_CHAT_MODEL
--set agents.soccer.env.SOCCER_INSTANTIATE_TIMEOUT_SECONDS=900
```
The translator block has no `INTERPRETER_` prefix: the chart adds it. A value can also read the chart Secret:
`{secret: <KEY>}`. Anything not listed goes in `<component>.extraEnv`. The full table, with defaults and what
the chart sets: [CONFIGURATION.md](CONFIGURATION.md).

Defaults of note: the LCM and operation-management keep their data in an in-memory H2 database (lost on
restart, as in compose); `CL_GOVERNANCE_URL` and `INSTANCE_PREFIX` have a placeholder as code default
(`{{...}}`), so they must stay set (the chart sets them). CL coordination is not configured: intent-lcm keeps
it off (`cl-coordination.enabled` defaults to `false`), so its placeholder URLs are never used.

## Mapping from compose

- Environment variables: same names and values as compose v3 (see above).
- `depends_on` -> init containers waiting for each TCP port (`global.waitImage`), plus readiness probes.
- `healthcheck` -> startup, readiness and liveness probes on the same URLs (`intent-lcm`: both JVMs;
  `operation-management`: `/deployments`).
- `env_file: .env.intend` -> only the keys the containers read: `OPENAI_API_KEY` in the Secret; the rest of
  `.env.intend` only fills compose variables (images, ports), which here are values.
- `container_name`, `ports`, `logging`, `restart`, `networks` -> not needed.

## What is verified, and what is not yet

Mock profile: only `helm lint` and `helm template`. Without the profile the rendered chart is identical to the one
before the mocks were added. With it: the three mocks, their Services and probes, the ConfigMap equal to
`intend/runtime/mock/application-closed-loop-profile.json`, intent-lcm and the agents pointed at the mocks, no
`10.30.*` address in the output; the "only InNet" and "only InOrch" variants render. Not installed on a cluster yet.

Verified on k3s (agents off): `helm lint`, install and upgrade; start order (data services, then
operation-management, intent-lcm after its waits and the ontology load, then the GUI); `ontology-init`
loads every graph (`VERIFY_GRAPHS_OK`); intent-lcm and the translator start with a real key; from the GUI pod
`/intent-manager-gui/`, `/tmf-api/intentManagement/v5/intent`, `/intent/query`, `/operation-management/` and
`/chat/` answer 200.

Verified with the agents on: each agent consumes `tasks` in its own Kafka group and ignores the tasks of the
others; a networking-only prompt ("private 5G connectivity for the sensors ... in Zone A, latency below 20 ms
in both directions, bandwidth at least 100 Mbps") gave one `NetworkExpectation` draft in 11 s; `CREATE_INTENT`
submitted it, operation-management sent the task to `3GPP_NSMF`, the agent selected `nst-ec21-001` and
instantiated the NSI; `DELETE` of the intent terminated it.

Test NSMF: the chart's `nsmf-mock` (already knows `nst-ec21-001`), with the mock profile or
`--set mocks.nsmf.enabled=true --set external.nsmf.baseUrl=""`. Send a prompt to the
translator as the GUI does: `GET http://<p>intent-lcm:8082/agentic/stream?message=<text>&conversationId=<id>`,
then the message `CREATE_INTENT` in the same conversation.

Not yet:
- a deployment intent through soccer-agent, and a real NSMF (OSM);
- whether the agents need probes (they publish no HTTP API that compose uses);
- the `knowledge-graph-bootstrap` hook Job.
