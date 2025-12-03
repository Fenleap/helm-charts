{{/*
Expand the name of the chart.
*/}}
{{- define "fenwave-backstage.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "fenwave-backstage.fullname" -}}
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
{{- define "fenwave-backstage.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "fenwave-backstage.labels" -}}
helm.sh/chart: {{ include "fenwave-backstage.chart" . }}
{{ include "fenwave-backstage.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "fenwave-backstage.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fenwave-backstage.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "fenwave-backstage.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "fenwave-backstage.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the secret to use
*/}}
{{- define "fenwave-backstage.secretName" -}}
{{- if .Values.existingSecret }}
{{- .Values.existingSecret }}
{{- else }}
{{- include "fenwave-backstage.fullname" . }}
{{- end }}
{{- end }}

{{/*
Create the name of the configmap to use
*/}}
{{- define "fenwave-backstage.configMapName" -}}
{{- if .Values.existingConfigMap }}
{{- .Values.existingConfigMap }}
{{- else }}
{{- printf "%s-config" (include "fenwave-backstage.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Create a default fully qualified postgresql name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "fenwave-backstage.postgresql.fullname" -}}
{{- if .Values.postgresql.fullnameOverride -}}
{{- .Values.postgresql.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "postgresql" .Values.postgresql.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/*
Return the PostgreSQL Hostname
*/}}
{{- define "fenwave-backstage.databaseHost" -}}
{{- if .Values.postgresql.enabled }}
    {{- if eq .Values.postgresql.architecture "replication" }}
        {{- include "fenwave-backstage.postgresql.fullname" . -}}-primary
    {{- else -}}
        {{- include "fenwave-backstage.postgresql.fullname" . -}}
    {{- end -}}
{{- else -}}
    {{- required "A valid externalDatabase.host is required" .Values.externalDatabase.host -}}
{{- end -}}
{{- end -}}

{{/*
Return the PostgreSQL Port
*/}}
{{- define "fenwave-backstage.databasePort" -}}
{{- if .Values.postgresql.enabled }}
    {{- .Values.postgresql.primary.service.ports.postgresql -}}
{{- else -}}
    {{- required "A valid externalDatabase.port is required" .Values.externalDatabase.port -}}
{{- end -}}
{{- end -}}

{{/*
Return the PostgreSQL Database Name
*/}}
{{- define "fenwave-backstage.databaseName" -}}
{{- if .Values.postgresql.enabled }}
    {{- .Values.postgresql.auth.database -}}
{{- else -}}
    {{- required "A valid externalDatabase.database is required" .Values.externalDatabase.database -}}
{{- end -}}
{{- end -}}

{{/*
Return the PostgreSQL User
*/}}
{{- define "fenwave-backstage.databaseUser" -}}
{{- if .Values.postgresql.enabled }}
    {{- .Values.postgresql.auth.username -}}
{{- else -}}
    {{- required "A valid externalDatabase.username is required" .Values.externalDatabase.username -}}
{{- end -}}
{{- end -}}

{{/*
Return the PostgreSQL Secret Name
*/}}
{{- define "fenwave-backstage.databaseSecretName" -}}
{{- if .Values.postgresql.enabled }}
    {{- include "fenwave-backstage.postgresql.fullname" . -}}
{{- else -}}
    {{- include "fenwave-backstage.secretName" . -}}
{{- end -}}
{{- end -}}
