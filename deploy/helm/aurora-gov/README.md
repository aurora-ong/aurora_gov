# Aurora Gov Helm Chart

A Helm chart for deploying Aurora Gov - Digital Governance Platform based on Collective Intelligence.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure (for PostgreSQL persistence)

## Installing the Chart

To install the chart with the release name `aurora-gov`:

```bash
# Add the repository (if using a Helm repository)
helm repo add aurora-gov https://charts.aurora.ong
helm repo update

# Install with default values
helm install aurora-gov aurora-gov/aurora-gov

# Install with custom values
helm install aurora-gov aurora-gov/aurora-gov -f values-production.yaml

# Install in a specific namespace
helm install aurora-gov aurora-gov/aurora-gov --namespace aurora-gov --create-namespace
```

## Uninstalling the Chart

To uninstall/delete the `aurora-gov` deployment:

```bash
helm uninstall aurora-gov
```

## Configuration

The following table lists the configurable parameters of the Aurora Gov chart and their default values.

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imageRegistry` | Global Docker image registry | `""` |
| `global.imagePullSecrets` | Global Docker registry secret names as an array | `[]` |
| `global.storageClass` | Global StorageClass for Persistent Volume(s) | `""` |

### Application Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `app.name` | Application name | `aurora-gov` |
| `app.replicaCount` | Number of Aurora Gov replicas | `1` |
| `app.image.registry` | Aurora Gov image registry | `registry.weychafe.nicher.cl` |
| `app.image.repository` | Aurora Gov image repository | `aurora_gov` |
| `app.image.tag` | Aurora Gov image tag | `0` |
| `app.image.pullPolicy` | Aurora Gov image pull policy | `IfNotPresent` |
| `app.phoenix.server` | Enable Phoenix server | `true` |
| `app.phoenix.port` | Phoenix server port | `4000` |
| `app.phoenix.host` | Phoenix server host | `gov.aurora.ong` |
| `app.phoenix.secretKeyBase` | Phoenix secret key base (auto-generated if empty) | `""` |
| `app.resources.requests.cpu` | CPU resource requests | `200m` |
| `app.resources.requests.memory` | Memory resource requests | `256Mi` |
| `app.resources.limits.cpu` | CPU resource limits | `500m` |
| `app.resources.limits.memory` | Memory resource limits | `512Mi` |

### Service Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Kubernetes service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Service target port | `4000` |
| `service.annotations` | Service annotations | `{}` |

### Ingress Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress controller resource | `true` |
| `ingress.className` | Ingress class name | `public` |
| `ingress.annotations` | Ingress annotations | See values.yaml |
| `ingress.hosts` | Ingress hosts configuration | See values.yaml |
| `ingress.tls` | Ingress TLS configuration | See values.yaml |

### PostgreSQL Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.enabled` | Deploy PostgreSQL container(s) | `true` |
| `postgresql.auth.postgresPassword` | PostgreSQL password (auto-generated if empty) | `""` |
| `postgresql.auth.database` | PostgreSQL database name | `aurora_gov` |
| `postgresql.image.registry` | PostgreSQL image registry | `docker.io` |
| `postgresql.image.repository` | PostgreSQL image repository | `postgres` |
| `postgresql.image.tag` | PostgreSQL image tag | `15-alpine` |
| `postgresql.persistence.enabled` | Enable PostgreSQL persistence | `true` |
| `postgresql.persistence.size` | PostgreSQL persistent volume size | `10Gi` |
| `postgresql.persistence.storageClass` | PostgreSQL storage class | `""` |
| `postgresql.resources.requests.cpu` | PostgreSQL CPU resource requests | `250m` |
| `postgresql.resources.requests.memory` | PostgreSQL memory resource requests | `512Mi` |

### Security Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `secrets.create` | Create secrets automatically | `true` |
| `secrets.existingSecret` | Name of existing secret to use | `""` |
| `serviceAccount.create` | Create service account | `true` |
| `serviceAccount.name` | Service account name | `""` |
| `rbac.create` | Create RBAC resources | `false` |

### Autoscaling Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable Horizontal Pod Autoscaler | `false` |
| `autoscaling.minReplicas` | Minimum number of replicas | `1` |
| `autoscaling.maxReplicas` | Maximum number of replicas | `10` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization percentage | `80` |
| `autoscaling.targetMemoryUtilizationPercentage` | Target memory utilization percentage | `80` |

## Examples

### Basic Installation

```bash
helm install aurora-gov ./helm/aurora-gov
```

### Production Installation

```bash
helm install aurora-gov ./helm/aurora-gov \
  --namespace aurora-gov \
  --create-namespace \
  --values ./helm/aurora-gov/values-production.yaml
```

### Development Installation

```bash
helm install aurora-gov-dev ./helm/aurora-gov \
  --namespace aurora-gov-dev \
  --create-namespace \
  --values ./helm/aurora-gov/values-development.yaml
```

### Custom Configuration

```bash
helm install aurora-gov ./helm/aurora-gov \
  --set app.replicaCount=3 \
  --set postgresql.persistence.size=50Gi \
  --set ingress.hosts[0].host=my-aurora.example.com
```

### Using External PostgreSQL

```bash
helm install aurora-gov ./helm/aurora-gov \
  --set postgresql.enabled=false \
  --set extraEnvVars[0].name=PROJECTOR_DATABASE_URL \
  --set extraEnvVars[0].value="ecto://user:pass@external-db:5432/aurora_projector" \
  --set extraEnvVars[1].name=EVENTSTORE_DATABASE_URL \
  --set extraEnvVars[1].value="ecto://user:pass@external-db:5432/aurora_eventstore"
```

## Upgrading

To upgrade the Aurora Gov deployment:

```bash
# Upgrade to latest version
helm upgrade aurora-gov aurora-gov/aurora-gov

# Upgrade with new values
helm upgrade aurora-gov aurora-gov/aurora-gov -f values-production.yaml

# Upgrade to specific version
helm upgrade aurora-gov aurora-gov/aurora-gov --version 0.2.0
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -n aurora-gov -l app.kubernetes.io/name=aurora-gov
```

### View Application Logs

```bash
kubectl logs -n aurora-gov -l app.kubernetes.io/name=aurora-gov -f
```

### Check Database Connection

```bash
kubectl exec -it -n aurora-gov deployment/aurora-gov-postgresql -- psql -U postgres -d aurora_gov
```

### Test Connectivity

```bash
helm test aurora-gov
```

### Debug Configuration

```bash
helm get values aurora-gov
helm get manifest aurora-gov
```

## Security Considerations

1. **Secrets Management**: The chart automatically generates secure passwords and secret keys. For production, consider using external secret management systems.

2. **Network Policies**: Enable network policies in production to restrict pod-to-pod communication.

3. **Security Contexts**: The chart includes security contexts with non-root users and dropped capabilities.

4. **TLS**: Configure proper TLS certificates for production deployments.

## Monitoring

The chart supports Prometheus monitoring when enabled:

```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
```

## Backup and Recovery

For PostgreSQL backup and recovery, consider:

1. Using PostgreSQL backup tools
2. Implementing persistent volume snapshots
3. Setting up automated backup schedules

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the chart
5. Submit a pull request

## License

This chart is licensed under the Elastic License 2.0 (ELv2).

## Support

For support and questions:
- Email: p.delgado@aurora.ong
- Website: https://aurora.ong
- Issues: Create an issue in the repository