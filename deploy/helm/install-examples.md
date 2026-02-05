# Aurora Gov Helm Installation Examples

Este documento contiene ejemplos prácticos para instalar Aurora Gov usando Helm en diferentes entornos.

## 🚀 Instalación Rápida (Desarrollo)

```bash
# Crear namespace
kubectl create namespace aurora-gov-dev

# Instalar con valores de desarrollo
helm install aurora-gov-dev ./helm/aurora-gov \
  --namespace aurora-gov-dev \
  --values ./helm/aurora-gov/values-development.yaml
```

## 🏭 Instalación de Producción

```bash
# Crear namespace
kubectl create namespace aurora-gov

# Instalar con valores de producción
helm install aurora-gov ./helm/aurora-gov \
  --namespace aurora-gov \
  --values ./helm/aurora-gov/values.yaml \
  --set app.phoenix.secretKeyBase="$(openssl rand -base64 64)" \
  --set postgresql.auth.postgresPassword="$(openssl rand -base64 32)"
```

## 🔧 Instalación Personalizada

### Con Base de Datos Externa

```bash
helm install aurora-gov ./helm/aurora-gov \
  --namespace aurora-gov \
  --create-namespace \
  --set postgresql.enabled=false \
  --set extraEnvVars[0].name=PROJECTOR_DATABASE_URL \
  --set extraEnvVars[0].value="ecto://postgres:mypassword@external-db.example.com:5432/aurora_projector" \
  --set extraEnvVars[1].name=EVENTSTORE_DATABASE_URL \
  --set extraEnvVars[1].value="ecto://postgres:mypassword@external-db.example.com:5432/aurora_eventstore"
```

### Con Dominio Personalizado

```bash
helm install aurora-gov ./helm/aurora-gov \
  --namespace aurora-gov \
  --create-namespace \
  --set app.phoenix.host="mi-aurora.ejemplo.com" \
  --set ingress.hosts[0].host="mi-aurora.ejemplo.com" \
  --set ingress.tls[0].hosts[0]="mi-aurora.ejemplo.com" \
  --set ingress.tls[0].secretName="mi-aurora-tls"
```

### Con Alta Disponibilidad

```bash
helm install aurora-gov ./helm/aurora-gov \
  --namespace aurora-gov \
  --create-namespace \
  --set app.replicaCount=3 \
  --set autoscaling.enabled=true \
  --set autoscaling.minReplicas=3 \
  --set autoscaling.maxReplicas=10 \
  --set podDisruptionBudget.enabled=true \
  --set podDisruptionBudget.minAvailable=2
```

## 📊 Instalación con Monitoreo

```bash
helm install aurora-gov ./helm/aurora-gov \
  --namespace aurora-gov \
  --create-namespace \
  --set monitoring.enabled=true \
  --set monitoring.serviceMonitor.enabled=true \
  --set podAnnotations."prometheus\.io/scrape"="true" \
  --set podAnnotations."prometheus\.io/port"="4000"
```

## 🔒 Instalación Segura

```bash
# Crear secrets manualmente
kubectl create secret generic aurora-gov-secrets \
  --namespace aurora-gov \
  --from-literal=secret-key-base="$(openssl rand -base64 64)" \
  --from-literal=postgres-password="$(openssl rand -base64 32)"

# Instalar usando secrets existentes
helm install aurora-gov ./helm/aurora-gov \
  --namespace aurora-gov \
  --set secrets.create=false \
  --set secrets.existingSecret="aurora-gov-secrets" \
  --set networkPolicy.enabled=true
```

## 🧪 Instalación de Testing

```bash
# Instalar para testing
helm install aurora-gov-test ./helm/aurora-gov \
  --namespace aurora-gov-test \
  --create-namespace \
  --set app.image.tag="test" \
  --set app.replicaCount=1 \
  --set postgresql.persistence.size=1Gi \
  --set ingress.hosts[0].host="test.aurora.local"

# Ejecutar tests
helm test aurora-gov-test --namespace aurora-gov-test
```

## 🔄 Actualización

```bash
# Actualizar a nueva versión
helm upgrade aurora-gov ./helm/aurora-gov \
  --namespace aurora-gov \
  --values ./helm/aurora-gov/values-production.yaml

# Actualizar con rollback automático en caso de fallo
helm upgrade aurora-gov ./helm/aurora-gov \
  --namespace aurora-gov \
  --values ./helm/aurora-gov/values-production.yaml \
  --atomic \
  --timeout 10m
```

## 🗑️ Desinstalación

```bash
# Desinstalar manteniendo PVCs
helm uninstall aurora-gov --namespace aurora-gov

# Desinstalar completamente (incluyendo PVCs)
helm uninstall aurora-gov --namespace aurora-gov
kubectl delete pvc -n aurora-gov --all
kubectl delete namespace aurora-gov
```

## 🔍 Comandos de Diagnóstico

```bash
# Ver estado del deployment
kubectl get all -n aurora-gov -l app.kubernetes.io/name=aurora-gov

# Ver logs de la aplicación
kubectl logs -n aurora-gov -l app.kubernetes.io/name=aurora-gov -f

# Ver logs de PostgreSQL
kubectl logs -n aurora-gov -l app.kubernetes.io/component=postgresql -f

# Conectar a la base de datos
kubectl exec -it -n aurora-gov deployment/aurora-gov-postgresql -- psql -U postgres -d aurora_gov

# Port forward para acceso local
kubectl port-forward -n aurora-gov service/aurora-gov 8080:80

# Ver configuración actual
helm get values aurora-gov -n aurora-gov
helm get manifest aurora-gov -n aurora-gov
```

## 📝 Archivo de Valores Personalizado

Crear `my-values.yaml`:

```yaml
app:
  replicaCount: 2
  phoenix:
    host: "mi-aurora.ejemplo.com"
  resources:
    requests:
      cpu: 300m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 1Gi

postgresql:
  persistence:
    size: 20Gi
    storageClass: "fast-ssd"
  resources:
    requests:
      cpu: 500m
      memory: 1Gi

ingress:
  hosts:
    - host: mi-aurora.ejemplo.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: mi-aurora-tls
      hosts:
        - mi-aurora.ejemplo.com

autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
```

Luego instalar:

```bash
helm install aurora-gov ./helm/aurora-gov \
  --namespace aurora-gov \
  --create-namespace \
  --values my-values.yaml
```

## 🚨 Solución de Problemas Comunes

### Pod en estado CrashLoopBackOff

```bash
# Ver logs detallados
kubectl describe pod -n aurora-gov -l app.kubernetes.io/name=aurora-gov
kubectl logs -n aurora-gov -l app.kubernetes.io/name=aurora-gov --previous
```

### Problemas de conectividad a la base de datos

```bash
# Verificar servicio de PostgreSQL
kubectl get svc -n aurora-gov -l app.kubernetes.io/component=postgresql

# Probar conectividad
kubectl run -it --rm debug --image=postgres:15-alpine --restart=Never -- psql -h aurora-gov-postgresql-service -U postgres -d aurora_gov
```

### Problemas con Ingress

```bash
# Verificar ingress
kubectl get ingress -n aurora-gov
kubectl describe ingress -n aurora-gov aurora-gov

# Verificar certificados TLS
kubectl get certificate -n aurora-gov
kubectl describe certificate -n aurora-gov aurora-gov-tls
```