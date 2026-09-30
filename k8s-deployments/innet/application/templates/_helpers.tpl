{{/*
Chart name
*/}}
{{- define "innet.name" -}}
{{- .Chart.Name -}}
{{- end }}


{{/*
Full release name
*/}}
{{- define "innet.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}


{{/*
Image pull secrets

If imagePullSecrets.name is defined, add the corresponding
Kubernetes Secret to the Pod specification.
*/}}
{{- define "innet.imagePullSecrets" -}}
{{- if .Values.imagePullSecrets.name }}
imagePullSecrets:
  - name: {{ .Values.imagePullSecrets.name | quote }}
{{- end }}
{{- end }}