{{- define "insustain.imagePullSecrets" -}}
{{- if .Values.imagePullSecrets.name }}
imagePullSecrets:
  - name: {{ .Values.imagePullSecrets.name | quote }}
{{- end }}
{{- end }}

{{- define "insustain.backendImage" -}}
{{- required "backend.image.digest must be set to the digest published by GitLab CI" .Values.backend.image.digest -}}
{{- end }}

{{- define "insustain.frontendImage" -}}
{{- required "frontend.image.digest must be set to the digest published by GitLab CI" .Values.frontend.image.digest -}}
{{- end }}

{{- define "insustain.serviceAccountName" -}}
{{- if .Values.rbac.create -}}
{{- default "insustain-backend" .Values.serviceAccount.name -}}
{{- else -}}
{{- required "serviceAccount.name is required when rbac.create=false" .Values.serviceAccount.name -}}
{{- end -}}
{{- end }}

{{- define "insustain.validate" -}}
{{- if and (not .Values.rbac.create) (or .Values.rbac.clusterWide .Values.rbac.targetNamespaces) -}}
{{- fail "rbac.create=false requires clusterWide=false and targetNamespaces=[]; provision grants externally" -}}
{{- end -}}
{{- if and .Values.rbac.clusterWide .Values.rbac.targetNamespaces -}}
{{- fail "rbac.targetNamespaces cannot be combined with rbac.clusterWide" -}}
{{- end -}}
{{- end }}

{{- define "insustain.secretName" -}}
{{- default (printf "%s-secrets" .Release.Name) .Values.secrets.existingSecret -}}
{{- end }}
