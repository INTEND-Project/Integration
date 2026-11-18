{{/*
Object names are the compose service names. global.namePrefix goes in front of the application components only
(intent-lcm, operation-management, the GUI, the agents, the knowledge graph Job: im.name); the data services
(StatefulSets) and the mocks keep the plain compose names. Every name a component uses to reach another one is
computed here from the same names. The label app.kubernetes.io/name stays the component name; selectors also carry the
release, so two releases with different prefixes can share a namespace.
*/}}

{{/* im.name: dict root, name -> "<global.namePrefix>-<name>", or <name> when the prefix is empty */}}
{{- define "im.name" -}}
{{- $p := .root.Values.global.namePrefix | default "" | toString -}}
{{- if $p -}}
{{- if or (gt (len $p) 30) (not (regexMatch "^[a-z]([-a-z0-9]*[a-z0-9])?$" $p)) -}}
{{- fail (printf "global.namePrefix %q: lower-case letters, digits and '-', starting with a letter and not ending with '-', at most 30 characters (e.g. innet-and-inorch)" $p) -}}
{{- end -}}
{{- printf "%s-%s" $p .name -}}
{{- else -}}
{{- .name -}}
{{- end -}}
{{- end }}

{{/* im.dataHost: dict root, key, host, enabled, name -> external.<key>.host if set, else the Service of this
chart (compose name, no prefix) if it is deployed, else an error */}}
{{- define "im.dataHost" -}}
{{- if .host -}}
{{- .host -}}
{{- else if .enabled -}}
{{- .name -}}
{{- else -}}
{{- fail (printf "external.%s.host is required when %s.enabled=false" .key .key) -}}
{{- end -}}
{{- end }}

{{- define "im.postgresHost" -}}
{{- include "im.dataHost" (dict "root" . "key" "postgres" "host" .Values.external.postgres.host "enabled" .Values.postgres.enabled "name" "intent-manager-postgres") -}}
{{- end }}

{{- define "im.fusekiHost" -}}
{{- include "im.dataHost" (dict "root" . "key" "fuseki" "host" .Values.external.fuseki.host "enabled" .Values.fuseki.enabled "name" "fuseki") -}}
{{- end }}

{{- define "im.qdrantHost" -}}
{{- include "im.dataHost" (dict "root" . "key" "qdrant" "host" .Values.external.qdrant.host "enabled" .Values.qdrant.enabled "name" "qdrant") -}}
{{- end }}

{{- define "im.kafkaHost" -}}
{{- include "im.dataHost" (dict "root" . "key" "kafka" "host" .Values.external.kafka.host "enabled" .Values.kafka.enabled "name" "kafka") -}}
{{- end }}

{{/* im.kafkaBootstrap: external.kafka.bootstrapServers, or <kafka host>:<port> */}}
{{- define "im.kafkaBootstrap" -}}
{{- .Values.external.kafka.bootstrapServers | default (printf "%s:%v" (include "im.kafkaHost" .) .Values.external.kafka.port) -}}
{{- end }}

{{/* im.systemUrl: dict root, key, url, mock (mocks.<x>), name, path -> external URL if set, else the mock of this
chart (compose name, no prefix) if it is on, else an error */}}
{{- define "im.systemUrl" -}}
{{- if .url -}}
{{- .url -}}
{{- else if .mock.enabled -}}
{{- printf "http://%s:%v%s" .name .mock.port (default "" .path) -}}
{{- else -}}
{{- fail (printf "%s is empty and the %s mock is off: set one of them" .key .name) -}}
{{- end -}}
{{- end }}

{{- define "im.labels" -}}
app.kubernetes.io/part-of: intent-manager
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{/* im.selector: "name" -> selector labels of a component */}}
{{- define "im.selector" -}}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
{{- end }}

{{/* im.image: dict root, image (repository, tag) */}}
{{- define "im.image" -}}
{{- $g := .root.Values.global -}}
{{- printf "%s/%s:%s" $g.imageRegistry .image.repository (default $g.imageTag .image.tag) -}}
{{- end }}

{{- define "im.secretName" -}}
{{- default (printf "%s-secrets" .Release.Name) .Values.secrets.existingSecret -}}
{{- end }}

{{/*
Environment of a container, built in two steps:
1. the template creates a dict with the values the chart computes (from external.*, topics, Service names);
   a value {secret: KEY} means "read KEY from the chart Secret";
2. im.overlay copies over it every entry of <component>.env that is not null (~), so values.yaml always wins.
A variable left at ~ and not computed by the chart is not set at all: the application uses its own default.
*/}}

{{/* im.overlay: dict dst, src, prefix -> sets dst[prefix+name] for each non-null src entry (mutates dst) */}}
{{- define "im.overlay" -}}
{{- $dst := .dst -}}
{{- $p := default "" .prefix -}}
{{- range $k, $v := (default (dict) .src) }}
{{- if not (kindIs "invalid" $v) }}
{{- $_ := set $dst (printf "%s%s" $p $k) $v }}
{{- end }}
{{- end }}
{{- end }}

{{/* im.envList: dict root, env -> env entries sorted by name */}}
{{- define "im.envList" -}}
{{- $root := .root -}}
{{- range $k, $v := .env }}
- name: {{ $k }}
{{- if kindIs "map" $v }}
  valueFrom:
    secretKeyRef:
      name: {{ include "im.secretName" $root }}
      key: {{ $v.secret }}
{{- else }}
  value: {{ $v | toString | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/* im.waitFor: dict root, targets (list of "host:port") -> one init container per target */}}
{{- define "im.waitFor" -}}
{{- $root := .root -}}
{{- range $i, $t := .targets }}
- name: wait-{{ $i }}
  image: {{ $root.Values.global.waitImage }}
  imagePullPolicy: {{ $root.Values.global.imagePullPolicy }}
  command: ["sh", "-c", "until nc -z -w 2 {{ (split ":" $t)._0 }} {{ (split ":" $t)._1 }}; do echo waiting for {{ $t }}; sleep 3; done"]
{{- end }}
{{- end }}

{{/* im.podCommon: no service links (a Service "kafka" would inject KAFKA_PORT, which the Confluent images
reject), imagePullSecrets and hostAliases */}}
{{- define "im.podCommon" -}}
enableServiceLinks: false
{{- with .Values.global.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.global.hostAliases }}
hostAliases:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.global.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.global.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}

{{/* im.pvc: dict name, storage (size, storageClass) -> volumeClaimTemplates entry */}}
{{- define "im.pvc" -}}
- metadata:
    name: {{ .name }}
  spec:
    accessModes: [ReadWriteOnce]
    {{- with .storage.storageClass }}
    storageClassName: {{ . }}
    {{- end }}
    resources:
      requests:
        storage: {{ .storage.size }}
{{- end }}

{{/* im.service: dict root, name, component, ports (list of dicts name/port) */}}
{{- define "im.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ .name }}
  labels:
    {{- include "im.labels" .root | nindent 4 }}
    app.kubernetes.io/name: {{ .component }}
spec:
  selector:
    {{- include "im.selector" (dict "name" .component "root" .root) | nindent 4 }}
  ports:
    {{- range .ports }}
    - {name: {{ .name }}, port: {{ .port }}, targetPort: {{ .port }}}
    {{- end }}
{{- end }}

{{- define "im.fusekiUrl" -}}
{{- printf "http://%s:%v" (include "im.fusekiHost" .) .Values.external.fuseki.port -}}
{{- end }}

