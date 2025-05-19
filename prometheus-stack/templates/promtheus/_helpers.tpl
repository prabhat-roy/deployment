{{- /*
Prometheus helper templates for labels and naming conventions
*/ -}}

{{- define "prometheus.name" -}}
{{- default .Chart.Name .Values.prometheus.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "prometheus.fullname" -}}
{{- printf "%s-%s" (include "prometheus.name" .) "server" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "prometheus.labels" -}}
app.kubernetes.io/name: {{ include "prometheus.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}
