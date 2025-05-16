{{/*
PostgreSQL Connection String builder
*/}}
{{- define "infisical-db-secure.postgresConnectionString" -}}
{{- if .Values.dbExternal.postgres.enabled -}}
{{- $pgParams := .Values.dbExternal.postgres -}}
{{- if and $pgParams.username $pgParams.host $pgParams.port $pgParams.database -}}
{{- $sslParams := "" -}}
{{- if $pgParams.ssl.enabled -}}
{{- if $pgParams.ssl.mode -}}
{{- $sslParams = printf "?sslmode=%s" $pgParams.ssl.mode -}}
{{- if $pgParams.ssl.rootCertPath -}}
{{- $sslParams = printf "%s&sslrootcert=%s" $sslParams $pgParams.ssl.rootCertPath -}}
{{- end -}}
{{- else -}}
{{- $sslParams = printf "?sslmode=disable" -}}
{{- end -}}
{{- else -}}
{{- $sslParams = printf "?sslmode=disable" -}}
{{- end -}}
{{- printf "postgresql://%s:$(DB_PASSWORD)@%s:%v/%s%s" $pgParams.username $pgParams.host $pgParams.port $pgParams.database $sslParams -}}
{{- else -}}
{{- fail "PostgreSQL custom URI parameters missing required fields (username, host, port, database)" -}}
{{- end -}}
{{- else -}}
{{- print "" -}}
{{- end -}}
{{- end -}}

{{/*
Redis Connection String builder
*/}}
{{- define "infisical-db-secure.redisConnectionString" -}}
{{- if .Values.dbExternal.redis.enabled -}}
{{- $redisParams := .Values.dbExternal.redis -}}
{{- if and $redisParams.host $redisParams.port -}}
{{- printf "redis://default:$(REDIS_PASSWORD)@%s:%v" $redisParams.host $redisParams.port -}}
{{- else -}}
{{- fail "Redis custom URI parameters missing required fields (host, port)" -}}
{{- end -}}
{{- else -}}
{{- print "" -}}
{{- end -}}
{{- end -}}
