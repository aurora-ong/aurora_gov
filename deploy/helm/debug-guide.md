# 🔍 Guía de Debug para Aurora Gov Helm Chart

Esta guía te ayudará a diagnosticar y resolver problemas durante la instalación y ejecución de Aurora Gov.

## 🚀 Debug Pre-Instalación

### 1. Validar el Chart

```bash
# Validar sintaxis del chart
helm lint ./helm/aurora-gov

# Validar con valores específicos
helm lint ./helm/aurora-gov -f ./helm/aurora-gov/values-production.yaml

# Verificar templates sin instalar
helm template aurora-gov ./helm/aurora-gov --debug

# Verificar templates con valores específicos
helm template aurora-gov ./helm/aurora-gov \
  -f ./helm/aurora-gov/values-production.yaml \
  --debug
```

### 2. Dry Run (Simulación)

```bash
# Simular instalación sin aplicar cambios
helm install aurora-gov ./helm/aurora-gov \
  --namespace aurora-gov \
  --create-namespace \
  --dry-run --debug

# Con valores de producción
helm install aurora-gov ./helm/aurora-gov --namespace aurora-gov --create-namespace --values ./helm/aurora-gov/values-production.yaml --dry-run --debug
```

### 3. Verificar Recursos del Cluster

```bash
# Verificar que el cluster esté disponible
kubectl cluster-info

# Verificar nodos
kubectl get nodes

# Verificar storage classes disponibles
kubectl get storageclass

# Verificar ingress controllers
kubectl get ingressclass

# Verificar cert-manager (si usas TLS)
kubectl get pods -n cert-manager
```

## 🔧 Debug Durante la Instalación

### 1. Instalación con Debug Habilitado

```bash
# Instalación con máximo debug
helm install aurora-gov ./helm/aurora-gov --namespace aurora-gov --create-namespace --values ./helm/aurora-gov/values-development.yaml --debug --wait --timeout 10m
```

### 2. Monitorear la Instalación

```bash
# En otra terminal, monitorear pods
watch kubectl get pods -n aurora-gov

# Monitorear eventos
kubectl get events -n aurora-gov --sort-by='.lastTimestamp'

# Monitorear todos los recursos
watch kubectl get all -n aurora-gov
```

## 🚨 Debug Post-Instalación

### 1. Estado General

```bash
# Ver estado del release
helm status aurora-gov -n aurora-gov

# Ver todos los recursos creados
kubectl get all -n aurora-gov -l app.kubernetes.io/instance=aurora-gov

# Ver configuración aplicada
helm get values aurora-gov -n aurora-gov

# Ver manifests generados
helm get manifest aurora-gov -n aurora-gov
```

### 2. Debug de Pods

```bash
# Ver estado detallado de pods
kubectl describe pods -n aurora-gov -l app.kubernetes.io/name=aurora-gov

# Ver logs de la aplicación
kubectl logs -n aurora-gov -l app.kubernetes.io/name=aurora-gov -f

# Ver logs anteriores (si el pod se reinició)
kubectl logs -n aurora-gov -l app.kubernetes.io/name=aurora-gov --previous

# Ver logs de PostgreSQL
kubectl logs -n aurora-gov -l app.kubernetes.io/component=postgresql -f

# Entrar al pod para debug
kubectl exec -it -n aurora-gov deployment/aurora-gov -- /bin/sh
```

### 3. Debug de Networking

```bash
# Verificar services
kubectl get svc -n aurora-gov
kubectl describe svc -n aurora-gov aurora-gov

# Verificar endpoints
kubectl get endpoints -n aurora-gov

# Verificar ingress
kubectl get ingress -n aurora-gov
kubectl describe ingress -n aurora-gov aurora-gov

# Test de conectividad interna
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup aurora-gov.aurora-gov.svc.cluster.local
```

### 4. Debug de Storage

```bash
# Verificar PVCs
kubectl get pvc -n aurora-gov
kubectl describe pvc -n aurora-gov

# Verificar PVs
kubectl get pv

# Ver eventos de storage
kubectl get events -n aurora-gov --field-selector reason=FailedMount
```

### 5. Debug de Secrets y ConfigMaps

```bash
# Verificar secrets
kubectl get secrets -n aurora-gov
kubectl describe secret -n aurora-gov aurora-gov-secrets

# Ver contenido de secrets (base64 decoded)
kubectl get secret -n aurora-gov aurora-gov-secrets -o jsonpath='{.data.secret-key-base}' | base64 -d

# Verificar configmaps
kubectl get configmap -n aurora-gov
kubectl describe configmap -n aurora-gov
```

## 🔍 Problemas Comunes y Soluciones

### 1. Pod en CrashLoopBackOff

```bash
# Ver razón del crash
kubectl describe pod -n aurora-gov <pod-name>

# Ver logs del crash
kubectl logs -n aurora-gov <pod-name> --previous

# Posibles causas:
# - SECRET_KEY_BASE vacío o inválido
# - Error de conexión a base de datos
# - Puerto ya en uso
# - Recursos insuficientes
```

**Solución:**
```bash
# Verificar secrets
kubectl get secret -n aurora-gov aurora-gov-secrets -o yaml

# Regenerar secrets si es necesario
kubectl delete secret -n aurora-gov aurora-gov-secrets
helm upgrade aurora-gov ./helm/aurora-gov -n aurora-gov --reuse-values
```

### 2. Error de Conexión a Base de Datos

```bash
# Verificar que PostgreSQL esté corriendo
kubectl get pods -n aurora-gov -l app.kubernetes.io/component=postgresql

# Verificar logs de PostgreSQL
kubectl logs -n aurora-gov -l app.kubernetes.io/component=postgresql

# Test de conectividad
kubectl run -it --rm pg-test --image=postgres:15-alpine --restart=Never -- \
  psql -h aurora-gov-postgresql-service.aurora-gov.svc.cluster.local -U postgres -d aurora_gov
```

**Solución:**
```bash
# Verificar service de PostgreSQL
kubectl get svc -n aurora-gov aurora-gov-postgresql-service

# Verificar que las URLs de conexión sean correctas
kubectl get secret -n aurora-gov aurora-gov-secrets -o jsonpath='{.data.projector-database-url}' | base64 -d
```

### 3. Problemas con Ingress/TLS

```bash
# Verificar ingress controller
kubectl get pods -n ingress-nginx

# Verificar certificados
kubectl get certificate -n aurora-gov
kubectl describe certificate -n aurora-gov aurora-gov-tls

# Ver logs del cert-manager
kubectl logs -n cert-manager -l app=cert-manager
```

**Solución:**
```bash
# Verificar issuer
kubectl get clusterissuer

# Forzar renovación de certificado
kubectl delete certificate -n aurora-gov aurora-gov-tls
```

### 4. Recursos Insuficientes

```bash
# Ver uso de recursos
kubectl top nodes
kubectl top pods -n aurora-gov

# Ver eventos de scheduling
kubectl get events -n aurora-gov --field-selector reason=FailedScheduling
```

**Solución:**
```bash
# Reducir recursos en values
helm upgrade aurora-gov ./helm/aurora-gov -n aurora-gov \
  --set app.resources.requests.cpu=100m \
  --set app.resources.requests.memory=128Mi
```

## 🛠️ Comandos de Debug Avanzado

### 1. Debug de Templates

```bash
# Ver template específico
helm template aurora-gov ./helm/aurora-gov \
  --show-only templates/deployment.yaml \
  --debug

# Ver con valores específicos
helm template aurora-gov ./helm/aurora-gov \
  --show-only templates/secret.yaml \
  --set app.phoenix.secretKeyBase="test-key" \
  --debug
```

### 2. Debug de Valores

```bash
# Ver todos los valores computados
helm template aurora-gov ./helm/aurora-gov \
  --debug 2>&1 | grep -A 1000 "COMPUTED VALUES:"

# Ver valores específicos
helm template aurora-gov ./helm/aurora-gov \
  --set app.replicaCount=3 \
  --debug | grep -A 10 "replicaCount"
```

### 3. Debug de Funciones Helper

```bash
# Test de función específica
helm template aurora-gov ./helm/aurora-gov \
  --show-only templates/deployment.yaml \
  --debug | grep "aurora-gov.image"
```

## 📊 Monitoreo Continuo

### 1. Script de Monitoreo

```bash
#!/bin/bash
# monitor-aurora.sh

NAMESPACE="aurora-gov"
RELEASE="aurora-gov"

echo "=== Aurora Gov Status ==="
helm status $RELEASE -n $NAMESPACE

echo -e "\n=== Pods Status ==="
kubectl get pods -n $NAMESPACE -l app.kubernetes.io/instance=$RELEASE

echo -e "\n=== Services Status ==="
kubectl get svc -n $NAMESPACE

echo -e "\n=== Ingress Status ==="
kubectl get ingress -n $NAMESPACE

echo -e "\n=== Recent Events ==="
kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | tail -10

echo -e "\n=== Resource Usage ==="
kubectl top pods -n $NAMESPACE 2>/dev/null || echo "Metrics server not available"
```

### 2. Logs Centralizados

```bash
# Ver todos los logs juntos
kubectl logs -n aurora-gov -l app.kubernetes.io/instance=aurora-gov --all-containers=true -f

# Logs con timestamps
kubectl logs -n aurora-gov -l app.kubernetes.io/name=aurora-gov --timestamps=true -f
```

## 🔄 Rollback y Recovery

### 1. Rollback

```bash
# Ver historial de releases
helm history aurora-gov -n aurora-gov

# Rollback a versión anterior
helm rollback aurora-gov 1 -n aurora-gov

# Rollback con debug
helm rollback aurora-gov 1 -n aurora-gov --debug
```

### 2. Recovery de Base de Datos

```bash
# Backup de datos (si es posible)
kubectl exec -n aurora-gov deployment/aurora-gov-postgresql -- \
  pg_dump -U postgres aurora_gov > backup.sql

# Restaurar datos
kubectl exec -i -n aurora-gov deployment/aurora-gov-postgresql -- \
  psql -U postgres aurora_gov < backup.sql
```

## 📝 Checklist de Debug

- [ ] Chart lint pasa sin errores
- [ ] Dry-run funciona correctamente
- [ ] Todos los pods están en estado Running
- [ ] Services tienen endpoints
- [ ] Ingress tiene IP asignada
- [ ] Secrets contienen datos válidos
- [ ] Base de datos acepta conexiones
- [ ] Aplicación responde en health checks
- [ ] Logs no muestran errores críticos
- [ ] Recursos suficientes disponibles

## 🆘 Obtener Ayuda

Si sigues teniendo problemas:

1. **Recopilar información:**
```bash
# Crear bundle de debug
kubectl cluster-info dump --namespaces aurora-gov --output-directory=debug-info
helm get all aurora-gov -n aurora-gov > debug-info/helm-info.yaml
```

2. **Contactar soporte:**
- Email: erarturo@outlook.com
- Incluir logs, manifests y descripción del problema
- Especificar versión de Kubernetes y Helm