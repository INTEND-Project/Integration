# Configuration reference

Every environment variable the Spring services read, extracted from the `master` branch of each repository
(`application.yaml` + `application-docker.yaml`, the profile the images run, plus `@Value` in the code).

- **Default**: the value used when the variable is not set. Empty = empty string; *(none)* = no default.
- Every variable below is listed in `values.yaml`, in the block named in each section. **values.yaml** shows
  what the chart sets out of the box: a value (the compose v3 one), `chart: ...` (computed from `external.*`,
  the topics or the Secret), or `~` (not set: the application default applies).
- To change one, set it in that block, e.g. `--set intentLcm.env.LOG_LEVEL_IT_NEXTWORKS=INFO`; a value
  there always wins over the computed one. `<component>.extraEnv` adds anything not listed.
- `<namePrefix>` in a computed value is `global.namePrefix` (default `innet-and-inorch`, application components
  only), see the README. `external.<x>` empty = the data service or mock of this release (no prefix).
- Rows marked *property* have no variable in the YAML: Spring still maps the variable shown (relaxed binding).
- The translator runs in the same container as the LCM and only receives `INTERPRETER_*` variables, without
  the prefix: in `values.yaml` set `<NAME>` under `intentLcm.translatorEnv` (the chart adds the prefix).

## intent-lcm container (start script)

`JAVA_OPTS` and `START_TRANSLATOR` are in `intentLcm.env`, the translator's `JAVA_OPTS` in
`intentLcm.translatorEnv` (passed as `INTERPRETER_JAVA_OPTS`). The translator port is fixed at 8082.

## intent-lcm: LCM (port 8080)

Block in values.yaml: `intentLcm.env`.

| Variable | Default | Spring property / origin | values.yaml |
|---|---|---|---|
| `BACKEND_ENV` | - | not read by the code (kept from compose) | `production` |
| `CL_GOVERNANCE_DRIVER` | `rest` | `cl-governance.driver` | `dummy` |
| `CL_GOVERNANCE_SLICER_URI` | `http://3gpp-nsmf/api/v1/` | `cl-governance.slicer-uri` *property* | ~ |
| `CL_GOVERNANCE_URL` | `{{CL_GOVERNANCE_URL}}` | `cl-governance.url` | chart: external.clg.governanceUrl |
| `INSTANCE_PREFIX` | `{{INSTANCE_PREFIX}}` | `tmf.instance-prefix` | chart: http://<namePrefix>-intent-lcm:8080/tmf-api/intentManagement/v5/intent/ |
| `INTENT_LCM_AUTOSTART` | `true` | `intent-lcm.autostart` | `true` |
| `INTENT_REPORT_KNOWLEDGE_GRAPH_UPLOAD_ENABLED` | `false` | `intent.report.knowledge-graph-upload.enabled` | `false` |
| `INTENT_REPORT_REFRESH_EXPIRING_WITHIN_SECONDS` | `30` | `intent.report.refresh.expiring-within-seconds` | ~ |
| `INTENT_REPORT_REFRESH_POLLER_DELAY_MS` | `15000` | `intent.report.refresh.poller-delay-ms` | ~ |
| `INTENT_REPORT_VALIDITY_MINUTES` | `10` | `intent.report.validity-minutes` | ~ |
| `LOG_LEVEL_IT_NEXTWORKS` | `DEBUG` | `logging.level.it.nextworks` | ~ |
| `OPENAPI_INTENTMANAGEMENT_BASE_PATH` | `/tmf-api/intentManagement/v5` | `openapi.intentManagement.base-path` *property* | ~ |
| `OPERATION_MANAGEMENT_DRIVER` | `rest` | `operation-management.driver` | ~ |
| `OPERATION_MANAGEMENT_DUMMY_DELAY_MS` | `1000` | `operation-management.dummy-delay-ms` | ~ |
| `OPERATION_MANAGEMENT_NOTIFICATION_URL` | `${OPERATION_MANAGER_NOTIFICATION_URL:${WORKFLOW_NOTIFICATION_URL:http…` | `operation-management.notification-url` | chart: http://<namePrefix>-intent-lcm:8080/api/notifications |
| `OPERATION_MANAGEMENT_URL` | `${OPERATION_MANAGER_URL:${WORKFLOW_MANAGER_URL:http://operation-manag…` | `operation-management.url` | chart: http://<namePrefix>-operation-management:8080 |
| `SERVER_PORT` | `8080` | `server.port` | `8080` |
| `SPARQL_DATA_ENDPOINT` | `http://fuseki:3030/intent/data` | `sparql.data.endpoint` | chart: external.fuseki |
| `SPARQL_ENDPOINT` | `http://fuseki:3030/intent/` | `sparql.sparql.endpoint` | chart: external.fuseki |
| `SPARQL_INSTANCE_GRAPH` | `https://github.com/INTEND-Project/inNet/blob/main/doc/inNet-intent-in…` | `sparql.instance-graph` | ~ |
| `SPARQL_ONTOLOGY_GRAPH` | `https://github.com/INTEND-Project/inNet/blob/main/doc/inNet-intent-on…` | `sparql.ontology-graph` | ~ |
| `SPARQL_PASSWORD` | `admin` | `sparql.credentials.password` | chart: Secret FUSEKI_ADMIN_PASSWORD |
| `SPARQL_UPDATE_ENDPOINT` | `http://fuseki:3030/intent/update` | `sparql.update.endpoint` | chart: external.fuseki |
| `SPARQL_USER` | `admin` | `sparql.credentials.user` | chart: external.fuseki.username |
| `SPRING_DATASOURCE_DRIVER` | `org.h2.Driver` | `spring.datasource.driverClassName` | ~ |
| `SPRING_DATASOURCE_PASSWORD` | `password` | `spring.datasource.password` | ~ |
| `SPRING_DATASOURCE_URL` | `jdbc:h2:mem:intent-repository` | `spring.datasource.url` | ~ |
| `SPRING_DATASOURCE_USERNAME` | `intent` | `spring.datasource.username` | ~ |
| `SPRING_JPA_DDL_AUTO` | `create` | `spring.hibernate.ddl-auto` | ~ |
| `SPRING_JPA_DIALECT` | `org.hibernate.dialect.H2Dialect` | `spring.jpa.spring.jpa.database-platform` | ~ |
| `SPRING_JPA_SHOW_SQL` | `false` | `spring.jpa.show-sql` | ~ |
| `SPRING_OUTPUT_ANSI_ENABLED` | `ALWAYS` | `spring.output.ansi.enabled` | ~ |
| `TMF_EVENT_PREDICATE` | `http://tio.models.tmforum.org/tio/v3.6.0/IntentManagementOntology/eve…` | `tmf.event-predicate` *property* | ~ |
| `TMF_ICM_PREFIX` | `http://tio.models.tmforum.org/tio/v3.6.0/IntentCommonModel/` | `tmf.icm-prefix` *property* | ~ |
| `TMF_IMO_PREFIX` | `http://tio.models.tmforum.org/tio/v3.6.0/IntentManagementOntology/` | `tmf.imo-prefix` *property* | ~ |
| `TMF_NXW_PREFIX` | `http://nextworks.it/intent#` | `tmf.nxw-prefix` *property* | ~ |
| `TMF_STATUS_PREDICATE` | `http://tio.models.tmforum.org/tio/v3.6.0/IntentManagementOntology/han…` | `tmf.status-predicate` *property* | ~ |
| `TRANSLATOR_APPLICATION_DEPLOYMENT_CLOSED_LOOP` | empty | `translator.application-deployment.closed-loop` | `` |
| `TRANSLATOR_APPLICATION_DEPLOYMENT_CLOSED_LOOP_PROFILE` | empty | `translator.application-deployment.closed-loop-profile` | `` |
| `TRANSLATOR_CHAIN` | `NetworkSliceTranslatorV2,DeploymentTranslatorV2` | `translator.translator-chain` | `NetworkSliceTranslatorV2,DeploymentTran…` |
| `TRANSLATOR_DEPLOYMENT_DESCRIPTOR_PROPERTY` | `http://5g4data.eu/5g4data#DeploymentDescriptor` | `translator.application-deployment.descriptor-property` | ~ |
| `TRANSLATOR_DEPLOYMENT_EXPECTATION_TYPE` | `http://5g4data.eu/5g4data#DeploymentExpectation` | `translator.application-deployment.expectation-type` | ~ |
| `TRANSLATOR_NETWORK_SLICE_CLOSED_LOOP` | `efda92a5-7632-4140-be0c-05c1705e1d7c` | `translator.network-slice.closed-loop` | `82399198-1685-4e97-903e-16b815e4b4a0` |
| `TRANSLATOR_NETWORK_SLICE_DEFAULT_AVAILABILITY` | `99.9` | `translator.network-slice.default.availability` | ~ |
| `TRANSLATOR_NETWORK_SLICE_DEFAULT_DOWNLINK_LATENCY` | `10` | `translator.network-slice.default.downlinkLatency` | ~ |
| `TRANSLATOR_NETWORK_SLICE_DEFAULT_DOWNLINK_THROUGHPUT` | `1000` | `translator.network-slice.default.downlinkThroughput` | ~ |
| `TRANSLATOR_NETWORK_SLICE_DEFAULT_JITTER` | `10` | `translator.network-slice.default.jitter` | ~ |
| `TRANSLATOR_NETWORK_SLICE_DEFAULT_UPLINK_LATENCY` | `10` | `translator.network-slice.default.uplinkLatency` | ~ |
| `TRANSLATOR_NETWORK_SLICE_DEFAULT_UPLINK_THROUGHPUT` | `100` | `translator.network-slice.default.uplinkThroughput` | ~ |
| `TRANSLATOR_NETWORK_SLICE_INTEND_DEFAULT_AVAILABILITY` | `99.9` | `translator.network-slice.intend-default.availability` | ~ |
| `TRANSLATOR_NETWORK_SLICE_INTEND_DEFAULT_DOWNLINK_LATENCY` | `10` | `translator.network-slice.intend-default.downlinkLatency` | ~ |
| `TRANSLATOR_NETWORK_SLICE_INTEND_DEFAULT_DOWNLINK_THROUGHPUT` | `1000000` | `translator.network-slice.intend-default.downlinkThroughput` | ~ |
| `TRANSLATOR_NETWORK_SLICE_INTEND_DEFAULT_JITTER` | `10` | `translator.network-slice.intend-default.jitter` | ~ |
| `TRANSLATOR_NETWORK_SLICE_INTEND_DEFAULT_UPLINK_LATENCY` | `10` | `translator.network-slice.intend-default.uplinkLatency` | ~ |
| `TRANSLATOR_NETWORK_SLICE_INTEND_DEFAULT_UPLINK_THROUGHPUT` | `100000` | `translator.network-slice.intend-default.uplinkThroughput` | ~ |

## intent-lcm: translator (port 8082)

Block in values.yaml: `intentLcm.translatorEnv`.

| Variable | Default | Spring property / origin | values.yaml |
|---|---|---|---|
| `INTERPRETER_INTENT_AGENTIC_ALLOW_JSON_LD` | `true` | `intent.agentic.allow-json-ld` | ~ |
| `INTERPRETER_INTENT_AGENTIC_ALLOW_TURTLE` | `true` | `intent.agentic.allow-turtle` | ~ |
| `INTERPRETER_INTENT_AGENTIC_CLARIFICATION_MODE` | `ask` | `intent.agentic.clarification.mode` | `ask` |
| `INTERPRETER_INTENT_AGENTIC_DEFAULT_FINAL_FORMAT` | `TURTLE` | `intent.agentic.default-final-format` | `TURTLE` |
| `INTERPRETER_INTENT_AGENTIC_ENABLED` | `true` | `intent.agentic.enabled` | ~ |
| `INTERPRETER_INTENT_AGENTIC_ENABLED_AGENTS` | empty | `intent.agentic.agents.enabled` | `NetworkExpectationAgent,DeploymentExpec…` |
| `INTERPRETER_INTENT_AGENTIC_FAIL_ON_INVALID_ARTIFACT` | `true` | `intent.agentic.fail-on-invalid-artifact` | ~ |
| `INTERPRETER_INTENT_AGENTIC_MAX_AGENT_OUTPUT_CHARS` | `16000` | `intent.agentic.max-agent-output-chars` | ~ |
| `INTERPRETER_INTENT_AGENTIC_MAX_FINAL_ARTIFACT_CHARS` | `40000` | `intent.agentic.max-final-artifact-chars` | ~ |
| `INTERPRETER_INTENT_AGENTIC_MAX_ITERATIONS` | `3` | `intent.agentic.max-iterations` | ~ |
| `INTERPRETER_INTENT_AGENTIC_ONTOLOGY_CHECK_NAMESPACES` | `icm,log,quan,set,imo,nxw,data5g` | `intent.agentic.ontology-check.namespaces` | ~ |
| `INTERPRETER_INTENT_AGENTIC_PROMPTS_EXTERNAL_DIR` | empty | `intent.agentic.prompts.external-dir` *property* | ~ |
| `INTERPRETER_INTENT_AGENTIC_QDRANT_CONTEXT_ENABLED` | `false` | `intent.agentic.qdrant-context-enabled` | ~ |
| `INTERPRETER_INTENT_AGENTIC_SUBMIT_ON_CONFIRM` | `true` | `intent.agentic.submit-on-confirm` | `true` |
| `INTERPRETER_INTENT_AGENTIC_TOKEN_LOGGING_ENABLED` | `false` | `intent.agentic.token-logging.enabled` | `true` |
| `INTERPRETER_INTENT_AGENTIC_V3_EXTRACTION_PARALLELISM` | `3` | `intent.agentic.v3.extraction-parallelism` | ~ |
| `INTERPRETER_INTENT_AGENTIC_V3_MAX_QUESTIONS_PER_COMPONENT` | `5` | `intent.agentic.v3.max-questions-per-component` | ~ |
| `INTERPRETER_INTENT_AGENTIC_V3_MAX_TURN_SECONDS` | `300` | `intent.agentic.v3.max-turn-seconds` | ~ |
| `INTERPRETER_INTENT_AGENTIC_V3_PER_COMPONENT_TIMEOUT_SECONDS` | `120` | `intent.agentic.v3.per-component-timeout-seconds` | ~ |
| `INTERPRETER_INTENT_APPLICATION_CATALOG_ENABLED` | `false` | `intent.agentic.application-catalog.enabled` | ~ |
| `INTERPRETER_INTENT_APPLICATION_CATALOG_ENDPOINT` | empty | `intent.agentic.application-catalog.endpoint` | ~ |
| `INTERPRETER_INTENT_APPLICATION_CATALOG_PROVIDER` | `soccer-mcp` | `intent.agentic.application-catalog.provider` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_CACHE_TTL_SECONDS` | `300` | `intent.ontology.cache.ttl-seconds` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_CONNECT_TIMEOUT_MS` | `3000` | `intent.ontology.fuseki.connect-timeout-ms` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_CONTEXT_MAX_METRICS` | `12` | `intent.ontology.context.max-metrics` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_CONTEXT_MAX_OPERATORS` | `8` | `intent.ontology.context.max-operators` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_CONTEXT_MAX_PROMPT_CHARS` | `12000` | `intent.ontology.context.max-prompt-chars` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_CONTEXT_MAX_TARGETS` | `8` | `intent.ontology.context.max-targets` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_CONTEXT_MAX_UNITS` | `8` | `intent.ontology.context.max-units` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_ENABLED` | `true` | `intent.ontology.enabled` | `true` |
| `INTERPRETER_INTENT_ONTOLOGY_FUSEKI_PASSWORD` | empty | `intent.ontology.fuseki.password` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_FUSEKI_QUERY_ENDPOINT` | `http://fuseki:3030/intent/query` | `intent.ontology.fuseki.query-endpoint` | chart: external.fuseki |
| `INTERPRETER_INTENT_ONTOLOGY_FUSEKI_USERNAME` | empty | `intent.ontology.fuseki.username` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_GRAPH_NXW_COMMON` | `https://ontology.nextworks.it/graphs/common/context/v1` | `intent.semantic.profiles.tmf-nxw.graphs.common` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_GRAPH_NXW_DOMAIN` | `https://nextworks.it/flecon/ontology/nextworks/domain/v1` | `intent.semantic.profiles.tmf-nxw.graphs.domain` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_GRAPH_NXW_EXTRACTION_PROFILE` | `https://nextworks.it/flecon/ontology/nextworks/extraction-profile/v1` | `intent.semantic.profiles.tmf-nxw.graphs.extraction-profile` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_GRAPH_NXW_INTENT_STRUCTURE` | `https://nextworks.it/flecon/ontology/nextworks/intent-structure/v1` | `intent.semantic.profiles.tmf-nxw.graphs.intent-structure` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_GRAPH_SPECIALIST_VOCABULARY` | `https://nextworks.it/ontology/specialist-vocabulary/v1` | `intent.semantic.profiles.tmf-nxw.graphs.specialist-vocabulary` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_GRAPH_TMFORUM_COMMON` | `https://nextworks.it/flecon/ontology/tmforum/v3.6.0/IntentCommonModel` | `intent.semantic.profiles.tmf.graphs.tmforum-common` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_GRAPH_TMFORUM_LOGICAL` | `https://nextworks.it/flecon/ontology/tmforum/v3.6.0/LogicalOperators` | `intent.semantic.profiles.tmf.graphs.tmforum-logical` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_GRAPH_TMFORUM_METRICS` | `https://nextworks.it/flecon/ontology/tmforum/v3.6.0/MetricsAndObserva…` | `intent.semantic.profiles.tmf.graphs.tmforum-metrics` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_GRAPH_TMFORUM_QUANTITY` | `https://nextworks.it/flecon/ontology/tmforum/v3.6.0/QuantityOntology` | `intent.semantic.profiles.tmf.graphs.tmforum-quantity` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_GRAPH_TMFORUM_SET` | `https://nextworks.it/flecon/ontology/tmforum/v3.6.0/SetOperators` | `intent.semantic.profiles.tmf.graphs.tmforum-set` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_READ_TIMEOUT_MS` | `10000` | `intent.ontology.fuseki.read-timeout-ms` | ~ |
| `INTERPRETER_INTENT_ONTOLOGY_REFRESH_ON_STARTUP` | `true` | `intent.ontology.cache.refresh-on-startup` | `true` |
| `INTERPRETER_INTENT_ONTOLOGY_REQUIRED` | `false` | `intent.ontology.required` | `false` |
| `INTERPRETER_INTENT_SEMANTIC_PROFILE` | `tmf-nxw` | `intent.semantic.active-profile` | ~ |
| `INTERPRETER_INTENT_SUBMISSION_URL` | `http://intent-lcm-backend:8080/tmf-api/intentManagement/v5/intent` | `intent.submission.url` | `http://localhost:8080/tmf-api/intentMan…` |
| `INTERPRETER_INTENT_V2_ONTOLOGY_ASSIST_ENABLED` | `false` | `intent.v2.ontology-assist.enabled` | ~ |
| `INTERPRETER_INTENT_V2_RAG_ENABLED` | `false` | `intent.v2.rag.enabled` | ~ |
| `INTERPRETER_INTENT_V2_RAG_INCLUDE_FUSEKI_ENRICHMENT` | `true` | `intent.v2.rag.include-fuseki-enrichment` | ~ |
| `INTERPRETER_INTENT_V2_RAG_INDEXING_ENABLED` | `false` | `intent.v2.rag.indexing.enabled` | ~ |
| `INTERPRETER_INTENT_V2_RAG_MAX_CONTEXT_CHARS` | `12000` | `intent.v2.rag.max-context-chars` | ~ |
| `INTERPRETER_INTENT_V2_RAG_SIMILARITY_THRESHOLD` | `0.70` | `intent.v2.rag.similarity-threshold` | ~ |
| `INTERPRETER_INTENT_V2_RAG_TOP_K` | `5` | `intent.v2.rag.top-k` | ~ |
| `INTERPRETER_OPENAI_API_KEY` | empty | `openai.api.key` | chart: Secret OPENAI_API_KEY |
| `INTERPRETER_QDRANT_COLLECTION` | `intent-knowledge` | `spring.ai.vectorstore.qdrant.collection-name` | chart: external.qdrant.collection |
| `INTERPRETER_QDRANT_HOST` | `qdrant` | `spring.ai.vectorstore.qdrant.host` | chart: external.qdrant.host |
| `INTERPRETER_QDRANT_PORT` | `6334` | `spring.ai.vectorstore.qdrant.port` | chart: external.qdrant.grpcPort |
| `INTERPRETER_SPRING_AI_OPENAI_API_KEY` | `${OPENAI_API_KEY:${openai.api.key}}` | `spring.ai.openai.api-key` | chart: Secret OPENAI_API_KEY |
| `INTERPRETER_SPRING_AI_OPENAI_CHAT_MODEL` | `gpt-6-luna` | `spring.ai.openai.chat.options.model` | ~ |
| `INTERPRETER_SPRING_AI_OPENAI_CHAT_REASONING_EFFORT` | `none` | `spring.ai.openai.chat.options.reasoning-effort` | ~ |
| `INTERPRETER_SPRING_DATASOURCE_PASSWORD` | - | overrides `spring.datasource.password` (YAML: `postgres`) | chart: Secret POSTGRES_PASSWORD |
| `INTERPRETER_SPRING_DATASOURCE_URL` | - | overrides `spring.datasource.url` (YAML: `jdbc:postgresql://postgres:5432/json_intents_v2`) | chart: external.postgres |
| `INTERPRETER_SPRING_DATASOURCE_USERNAME` | - | overrides `spring.datasource.username` (YAML: `postgres`) | chart: external.postgres.username |
| `INTERPRETER_TMF921_PROFILE_RESOLUTION_ENABLED` | `true` | `tmf921.profile-resolution.enabled` | `true` |
| `INTERPRETER_TMF921_PROFILE_URL` | `http://intent-lcm-backend:8080/tmf-api/intentManagement/v5/intentMana…` | `tmf921.profile.url` | `http://localhost:8080/tmf-api/intentMan…` |
| `INTERPRETER_TRANSLATOR_ENV` | - | not read by the code (kept from compose) | `production` |

## operation-management

Block in values.yaml: `operationManagement.env`.

| Variable | Default | Spring property / origin | values.yaml |
|---|---|---|---|
| `KAFKA_AGENT_TIMEOUTS_3GPP_NSMF` | - | `kafka.agent-timeouts.3GPP_NSMF` *property*: reply timeout of the NSMF agent | `120000` |
| `KAFKA_BOOTSTRAP_SERVERS` | *(none)* | `spring.kafka.bootstrap-servers` | chart: external.kafka.bootstrapServers (empty = kafka:9092) |
| `KAFKA_SOCCER_TIMEOUT_MS` | `900000` | `kafka.agent-timeouts.SOCCER` | ~ |
| `KAFKA_TIMEOUT` | `10000` | `kafka.timeout` *property* | ~ |
| `SPRING_KAFKA_GROUP_ID` | `operation-management` | `spring.kafka.group-id` *property* | ~ |
| `TASK_RESPONSE_TOPIC` | *(none)* | `kafka.topics.response` | chart: topics.response |
| `TASK_TOPIC` | *(none)* | `kafka.topics.command` | chart: topics.task |

## 3gpp-nsmf-agent

Block in values.yaml: `agents.nsmf.env`.

| Variable | Default | Spring property / origin | values.yaml |
|---|---|---|---|
| `AGENT_NSMF_TERMINATE_READY_POLL_SECONDS` | `5` | `agent.nsmf.terminate-ready-poll-seconds` *property* | ~ |
| `AGENT_NSMF_TERMINATE_READY_TIMEOUT_SECONDS` | `180` | `agent.nsmf.terminate-ready-timeout-seconds` *property* | ~ |
| `KAFKA_BOOTSTRAP_SERVERS` | *(none)* | `spring.kafka.bootstrap-servers` | chart: external.kafka.bootstrapServers (empty = kafka:9092) |
| `NSMF_BASE_URL` | `http://nsmf:8080` | `agent.nsmf.base-url` | chart: external.nsmf.baseUrl |
| `NSMF_CATALOGUE_PATH` | `/ns/catalogue/nstemplate` | `agent.nsmf.catalogue-path` | `/ns/catalogue/nstemplate` |
| `NSMF_CREATE_NSI_PATH` | `/vs/basic/nslcm/ns/nst` | `agent.nsmf.create-nsi-path` | `/vs/basic/nslcm/ns/nst` |
| `NSMF_INSTANTIATE_TEMPLATE` | `/vs/basic/nslcm/ns/%s/action/instantiate` | `agent.nsmf.instantiate-path-template` | `/vs/basic/nslcm/ns/%s/action/instantiate` |
| `NSMF_NS_LIST_PATH` | `/vs/basic/nslcm/ns` | `agent.nsmf.ns-list-path` | ~ |
| `NSMF_TERMINATE_TEMPLATE` | `/vs/basic/nslcm/ns/%s/action/terminate` | `agent.nsmf.terminate-path-template` | `/vs/basic/nslcm/ns/%s/action/terminate` |
| `SLEEP` | *(none)* | `agent.sleep` | `5` |
| `SPRING_KAFKA_GROUP_ID` | `operation-management` | `spring.kafka.group-id` *property* | ~ |
| `TASK_RESPONSE_TOPIC` | *(none)* | `kafka.topics.response` | chart: topics.response |
| `TASK_TOPIC` | *(none)* | `kafka.topics.command` | chart: topics.task |

## soccer-agent

Block in values.yaml: `agents.soccer.env`.

| Variable | Default | Spring property / origin | values.yaml |
|---|---|---|---|
| `KAFKA_BOOTSTRAP_SERVERS` | *(none)* | `spring.kafka.bootstrap-servers` | chart: external.kafka.bootstrapServers (empty = kafka:9092) |
| `SOCCER_AGENT_WORKERS` | `4` | `agent.workers` | ~ |
| `SOCCER_BASE_URL` | `http://soccer-mock:9090` | `soccer.base-url` | chart: external.soccer.baseUrl |
| `SOCCER_CATALOGUE_BASE_URL` | empty | `soccer.catalogue-base-url` | ~ |
| `SOCCER_DELETE_SERVICE_INSTANCE_AFTER_TERMINATE` | `true` | `soccer.delete-service-instance-after-terminate` | `false` |
| `SOCCER_INSTANTIATE_TIMEOUT_SECONDS` | `600` | `soccer.instantiate-timeout-seconds` | ~ |
| `SOCCER_POLL_INTERVAL_SECONDS` | `5` | `soccer.poll-interval-seconds` | ~ |
| `SOCCER_TENANT_ID` | empty | `soccer.tenant-id` | chart: external.soccer.tenantId |
| `TASK_RESPONSE_TOPIC` | *(none)* | `kafka.topics.response` | chart: topics.response |
| `TASK_TOPIC` | *(none)* | `kafka.topics.command` | chart: topics.task |

## intent-manager-gui

Block in values.yaml: `gui.env`.

| Variable | Default | Spring property / origin | values.yaml |
|---|---|---|---|
| `BE_URL` | empty | `env.js, not loaded by the image's index.html` | ~ |
| `FUSEKI_UPSTREAM` | `fuseki:3030` | `nginx upstream` | chart: external.fuseki host (full name if it has no dot):port |
| `FUSEKI_URL` | empty | `env.js, not loaded by the image's index.html` | ~ |
| `GRAPH_URI` | empty | `env.js, not loaded by the image's index.html` | `https://github.com/INTEND-Project/inNet…` |
| `INTENT_LCM_UPSTREAM` | `intent-lcm-backend:8080` | `nginx upstream` | chart: <namePrefix>-intent-lcm.<namespace>.svc.<clusterDomain>:8080 |
| `INTENT_TRANSLATOR_UPSTREAM` | `intent-translator:8080` | `nginx upstream` | chart: <namePrefix>-intent-lcm.<namespace>.svc.<clusterDomain>:8082 |
| `INTERPRETER_URL` | empty | `env.js, not loaded by the image's index.html` | ~ |
| `OPERATION_MANAGEMENT_UPSTREAM` | `operation-management:8080` | `nginx upstream` | chart: <namePrefix>-operation-management.<namespace>.svc.<clusterDomain>:8080 |
| `OPERATION_MANAGER_URL` | `/operation-management` | `env.js, not loaded by the image's index.html` | chart: /operation-management |

## ontology-init (init container of intent-lcm)

Block in values.yaml: `ontologyInit.env`.

| Variable | Default | Spring property / origin | values.yaml |
|---|---|---|---|
| `FUSEKI_ADMIN_PASSWORD` | `admin` | `loader` | chart: Secret FUSEKI_ADMIN_PASSWORD |
| `FUSEKI_BASE_URL` | `http://fuseki:3030` | `loader` | chart: external.fuseki |
| `FUSEKI_DATASET` | `intent` | `loader` | chart: external.fuseki.dataset |
| `FUSEKI_USERNAME` | `admin` | `loader` | chart: external.fuseki.username |
| `ONTOLOGY_BASE_DIR` | `/ontology` | `loader` | ~ |

## knowledge-graph-bootstrap (Job)

Block in values.yaml: `knowledgeGraphBootstrap.env`.

| Variable | Default | Spring property / origin | values.yaml |
|---|---|---|---|
| `CORPUS_PATH` | `/app/corpus/intent-knowledge-v2.json` | `load-corpus.sh` | `/app/corpus/intent-knowledge-v2.json` |
| `INTENT_INTERPRETER_BASE_URL` | `http://intent-translator:8080` | `load-corpus.sh` | chart: http://<namePrefix>-intent-lcm:8082 |
| `QDRANT_BASE_URL` | `http://qdrant:6333` | `load-corpus.sh` | chart: external.qdrant (HTTP) |
| `QDRANT_READY_ENDPOINT` | `/collections` | `load-corpus.sh` | `/collections` |
| `RAG_INDEX_ENDPOINT` | `/v2/rag/index` | `load-corpus.sh` | `/v2/rag/index` |
| `WAIT_SLEEP_SECONDS` | `3` | `load-corpus.sh` | `3` |
| `WAIT_TIMEOUT_SECONDS` | `180` | `load-corpus.sh` | `180` |
