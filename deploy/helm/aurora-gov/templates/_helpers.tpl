{{/*
Expand the name of the chart.
*/}}
{{- define "aurora-gov.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "aurora-gov.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "aurora-gov.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "aurora-gov.labels" -}}
helm.sh/chart: {{ include "aurora-gov.chart" . }}
{{ include "aurora-gov.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "aurora-gov.selectorLabels" -}}
app.kubernetes.io/name: {{ include "aurora-gov.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "aurora-gov.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "aurora-gov.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the secret to use
*/}}
{{- define "aurora-gov.secretName" -}}
{{- if .Values.secrets.existingSecret }}
{{- .Values.secrets.existingSecret }}
{{- else }}
{{- include "aurora-gov.fullname" . }}-secrets
{{- end }}
{{- end }}

{{/*
Create the name of the configmap to use
*/}}
{{- define "aurora-gov.configMapName" -}}
{{- include "aurora-gov.fullname" . }}-config
{{- end }}

{{/*
PostgreSQL fullname
*/}}
{{- define "aurora-gov.postgresql.fullname" -}}
{{- include "aurora-gov.fullname" . }}-postgresql
{{- end }}

{{/*
PostgreSQL secret name
*/}}
{{- define "aurora-gov.postgresql.secretName" -}}
{{- include "aurora-gov.postgresql.fullname" . }}-secrets
{{- end }}

{{/*
PostgreSQL service name
*/}}
{{- define "aurora-gov.postgresql.serviceName" -}}
{{- include "aurora-gov.postgresql.fullname" . }}-service
{{- end }}

{{/*
Create PostgreSQL connection URLs
*/}}
{{- define "aurora-gov.postgresql.projectorUrl" -}}
{{- printf "ecto://postgres:%s@%s:5432/%s_projector" (include "aurora-gov.postgresql.password" .) (include "aurora-gov.postgresql.serviceName" .) .Values.postgresql.auth.database }}
{{- end }}

{{- define "aurora-gov.postgresql.eventstoreUrl" -}}
{{- printf "ecto://postgres:%s@%s:5432/%s_eventstore" (include "aurora-gov.postgresql.password" .) (include "aurora-gov.postgresql.serviceName" .) .Values.postgresql.auth.database }}
{{- end }}

{{/*
Get PostgreSQL password
*/}}
{{- define "aurora-gov.postgresql.password" -}}
{{- if .Values.postgresql.auth.postgresPassword }}
{{- .Values.postgresql.auth.postgresPassword }}
{{- else }}
{{- randAlphaNum 16 }}
{{- end }}
{{- end }}

{{/*
Get Phoenix secret key base
*/}}
{{- define "aurora-gov.phoenix.secretKeyBase" -}}
{{- if .Values.app.phoenix.secretKeyBase }}
{{- .Values.app.phoenix.secretKeyBase }}
{{- else }}
{{- randAlphaNum 64 }}
{{- end }}
{{- end }}

{{/*
Create image name
*/}}
{{- define "aurora-gov.image" -}}
{{- $registry := .Values.global.imageRegistry | default .Values.app.image.registry -}}
{{- $repository := .Values.app.image.repository -}}
{{- $tag := .Values.app.image.tag | default .Chart.AppVersion -}}
{{- if $registry }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- else }}
{{- printf "%s:%s" $repository $tag }}
{{- end }}
{{- end }}

{{/*
Create PostgreSQL image name
*/}}
{{- define "aurora-gov.postgresql.image" -}}
{{- $registry := .Values.global.imageRegistry | default .Values.postgresql.image.registry -}}
{{- $repository := .Values.postgresql.image.repository -}}
{{- $tag := .Values.postgresql.image.tag -}}
{{- if $registry }}
{{- printf "%s/%s:%s" $registry $repository $tag }}
{{- else }}
{{- printf "%s:%s" $repository $tag }}
{{- end }}
{{- end }}

{{/*
Return the proper Storage Class
*/}}
{{- define "aurora-gov.storageClass" -}}
{{- $storageClass := .Values.postgresql.persistence.storageClass -}}
{{- if .Values.global.storageClass -}}
    {{- $storageClass = .Values.global.storageClass -}}
{{- end -}}
{{- if $storageClass -}}
  {{- if (eq "-" $storageClass) -}}
      {{- printf "storageClassName: \"\"" -}}
  {{- else }}
      {{- printf "storageClassName: %s" $storageClass -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Compile all warnings into a single message.
*/}}
{{- define "aurora-gov.validateValues" -}}
{{- $messages := list -}}
{{- $messages := append $messages (include "aurora-gov.validateValues.postgresql" .) -}}
{{- $messages := append $messages (include "aurora-gov.validateValues.ingress" .) -}}
{{- $messages := without $messages "" -}}
{{- $message := join "\n" $messages -}}

{{- if $message -}}
{{-   printf "\nVALUES VALIDATION:\n%s" $message -}}
{{- end -}}
{{- end -}}

{{/*
Validate PostgreSQL configuration
*/}}
{{- define "aurora-gov.validateValues.postgresql" -}}
{{- if and .Values.postgresql.enabled (not .Values.postgresql.auth.database) -}}
aurora-gov: postgresql.auth.database
    Database name is required when PostgreSQL is enabled.
{{- end -}}
{{- end -}}

{{/*
Validate Ingress configuration
*/}}
{{- define "aurora-gov.validateValues.ingress" -}}
{{- if and .Values.ingress.enabled (not .Values.ingress.hosts) -}}
aurora-gov: ingress.hosts
    At least one host is required when Ingress is enabled.
{{- end -}}
{{- end -}}