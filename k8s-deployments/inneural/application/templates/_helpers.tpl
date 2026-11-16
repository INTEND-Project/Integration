{{/*
Chart name
*/}}
{{- define "inneural.name" -}}
{{- .Chart.Name -}}
{{- end }}


{{/*
Full release name
*/}}
{{- define "inneural.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}