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