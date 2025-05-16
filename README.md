# Infisical DB Secure Wrapper

[![Release Helm Chart](https://github.com/raulstechtips/infisical-standalone-db-secure-wrapper/actions/workflows/release.yml/badge.svg)](https://github.com/raulstechtips/infisical-standalone-db-secure-wrapper/actions/workflows/release.yml)
[![PR Validation](https://github.com/raulstechtips/infisical-standalone-db-secure-wrapper/actions/workflows/pr-validation.yml/badge.svg)](https://github.com/raulstechtips/infisical-standalone-db-secure-wrapper/actions/workflows/pr-validation.yml)

A minimal Helm chart wrapper for Infisical that adds secure database connections with SSL certificates support. This wrapper allows you to deploy Infisical with external PostgreSQL and Redis instances using SSL/TLS connections.

## Features

- Configures custom PostgreSQL connection with SSL support
- Configures custom Redis connection
- Uses Infisical's built-in volume mount capabilities for CA certificates
- Works as a thin wrapper around the upstream Infisical chart
- Passes through all upstream chart values directly

## Quick Start

```bash
# Add the repo
helm repo add infisical-secure https://yourusername.github.io/infisical-standalone-db-secure-wrapper
helm repo update

# Install the chart
helm install infisical infisical-secure/infisical-db-secure -f my-values.yaml
```

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- External PostgreSQL database with SSL support
- External Redis instance

## Installing the Chart

To install the chart with the release name `infisical`:

```bash
helm install infisical infisical-secure/infisical-db-secure -f values.yaml
```

## ArgoCD Integration

This chart can be managed by ArgoCD in two ways:

### 1. Directly from the Helm Repository

Create an Application CR that points to the GitHub Pages Helm chart repository:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: infisical
  namespace: argocd
spec:
  project: default
  source:
    chart: infisical-db-secure
    repoURL: https://yourusername.github.io/infisical-standalone-db-secure-wrapper
    targetRevision: 0.1.0  # Use specific chart version
    helm:
      values: |
        infisical:
          replicaCount: 3
        dbExternal:
          postgres:
            enabled: true
            # ... other values
  destination:
    server: https://kubernetes.default.svc
    namespace: infisical
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### 2. Using Kustomize with Helm

For more complex scenarios where you need to manage multiple resources:

1. Create a kustomization.yaml file:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: infisical

helmCharts:
  - name: infisical-db-secure
    repo: https://yourusername.github.io/infisical-standalone-db-secure-wrapper
    version: 0.1.0
    releaseName: infisical
    namespace: infisical
    valuesFile: values/prod.yaml

resources:
  - manifests/ingress/prod.yaml
  - manifests/secrets/infisical-secrets.yaml
```

2. Configure ArgoCD to use this kustomization:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: infisical-suite
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/infisical-kustomize.git
    targetRevision: HEAD
    path: path/to/kustomization
  destination:
    server: https://kubernetes.default.svc
    namespace: infisical
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

This allows you to manage multiple related resources alongside the Helm chart.

## Configuration

### Wrapper Chart Values Structure

The wrapper chart uses a clean structure with two main sections:

1. Direct upstream values - All values from the upstream Infisical chart can be specified directly at the root level
2. `dbExternal` - Special section for secure database connections

Example:

```yaml
# Direct upstream values
infisical:
  replicaCount: 3
  image:
    repository: infisical/infisical
    tag: v0.122.1-postgres
  # Use Infisical's built-in support for volume mounts
  extraVolumes:
    - name: postgres-ca-cert
      secret:
        secretName: postgres-ca-key-pair
        items:
        - key: ca.crt
          path: postgres-ca.crt
  extraVolumeMounts:
    - name: postgres-ca-cert
      mountPath: /etc/ssl/postgres-ca.crt
      readOnly: true

# Disable in-chart services, we'll use external services
postgresql:
  enabled: false
redis:
  enabled: false

# DB security wrapper features  
dbExternal:
  postgres:
    enabled: true
    host: "postgres.example.com"
    port: 5432
    database: "infisical"
    username: "infisical"
    passwordSecret:
      name: "postgres-credentials"
      key: "password"
    ssl:
      enabled: true
      mode: "verify-ca"
      rootCertPath: "/etc/ssl/postgres-ca.crt"
  redis:
    enabled: true
    host: "redis.example.com"
    port: 6379
    passwordSecret:
      name: "redis-credentials"
      key: "redis-password"
```

### DB Secure Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `dbExternal.postgres.enabled` | Enable custom PostgreSQL connection | `true` |
| `dbExternal.postgres.host` | PostgreSQL host | `""` |
| `dbExternal.postgres.port` | PostgreSQL port | `5432` |
| `dbExternal.postgres.database` | PostgreSQL database name | `""` |
| `dbExternal.postgres.username` | PostgreSQL username | `""` |
| `dbExternal.postgres.passwordSecret.name` | Secret containing PostgreSQL password | `""` |
| `dbExternal.postgres.passwordSecret.key` | Key in the secret containing PostgreSQL password | `""` |
| `dbExternal.postgres.ssl.enabled` | Enable SSL for PostgreSQL connection | `true` |
| `dbExternal.postgres.ssl.mode` | SSL mode for PostgreSQL connection (`verify-ca` or `verify-full`) | `"verify-ca"` |
| `dbExternal.redis.enabled` | Enable custom Redis connection | `true` |
| `dbExternal.redis.host` | Redis host | `""` |
| `dbExternal.redis.port` | Redis port | `6379` |
| `dbExternal.redis.passwordSecret.name` | Secret containing Redis password | `""` |
| `dbExternal.redis.passwordSecret.key` | Key in the secret containing Redis password | `""` |

### Direct Upstream Chart Values

For a complete list of upstream Infisical chart values, see the [official documentation](https://github.com/Infisical/infisical/tree/main/helm-charts/infisical).

## Development and CI/CD

This repository uses GitHub Actions to automate testing, security scanning, and chart publishing.

### PR Validation

All pull requests trigger a validation workflow that:
- Performs YAML linting
- Validates Helm chart structure
- Runs unit tests
- Validates chart templates
- Performs security scanning with Trivy
- Checks if chart version was properly incremented

### Release Process

When changes are merged to the main branch, the release workflow:
1. Runs all tests and validations
2. Performs security scanning
3. Packages the Helm chart
4. Updates the Helm repository index
5. Publishes to GitHub Pages
6. Creates a GitHub Release with release notes

### Local Testing

For local development and testing:

```bash
# Lint the chart
helm lint .

# Run template validation
helm template . | kubeval --strict

# Package the chart locally
helm package .

# Test with real clusters
helm install infisical-test . --dry-run

# Dependency update
helm dependency update .
```

## License

This wrapper chart is licensed under the same terms as the upstream Infisical chart.
