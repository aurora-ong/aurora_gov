# 🗑️ Guía de Desinstalación de Aurora Gov

Esta guía te ayudará a desinstalar completamente Aurora Gov de tu cluster de Kubernetes.

## 🚀 Desinstalación Básica

### 1. Desinstalar el Release de Helm

```bash
# Desinstalar el release
helm uninstall aurora-gov --namespace aurora-gov

# Verificar que se desinstaló
helm list --namespace aurora-gov
```

### 2. Verificar Recursos Eliminados

```bash
# Verificar que los pods se eliminaron
kubectl get pods -n aurora-gov

# Verificar que los services se eliminaron
kubectl get svc -n aurora-gov

# Verificar que los ingress se eliminaron
kubectl get ingress -n aurora-gov
```

## 🧹 Desinstalación Completa (Incluyendo Datos)

### 1. Desinstalar Release

```bash
helm uninstall aurora-gov --namespace aurora-gov
```

### 2. Eliminar Persistent Volume Claims (PVCs)

⚠️ **ADVERTENCIA: Esto eliminará TODOS los datos de la base de datos**

```bash
# Ver PVCs existentes
kubectl get pvc -n aurora-gov

# Eliminar PVCs específicos de Aurora Gov
kubectl delete pvc -n aurora-gov -l app.kubernetes.io/instance=aurora-gov

# O eliminar todos los PVCs del namespace
kubectl delete pvc --all -n aurora-gov
```

### 3. Eliminar Persistent Volumes (PVs) si es necesario

```bash
# Ver PVs que podrían estar huérfanos
kubectl get pv | grep aurora-gov

# Eliminar PVs específicos (solo si están en estado Available)
kubectl delete pv <pv-name>
```

### 4. Eliminar Secrets y ConfigMaps restantes

```bash
# Eliminar secrets
kubectl delete secret -n aurora-gov -l app.kubernetes.io/instance=aurora-gov

# Eliminar configmaps
kubectl delete configmap -n aurora-gov -l app.kubernetes.io/instance=aurora-gov
```

### 5. Eliminar el Namespace (Opcional)

```bash
# Eliminar todo el namespace (esto elimina TODOS los recursos)
kubectl delete namespace aurora-gov
```

## 🔄 Desinstalación con Backup de Datos

### 1. Hacer Backup de la Base de Datos

```bash
# Crear backup antes de desinstalar
kubectl exec -n aurora-gov deployment/aurora-gov-postgresql -- \
  pg_dump -U postgres aurora_gov > aurora-gov-backup-$(date +%Y%m%d).sql

# Verificar que el backup se creó
ls -la aurora-gov-backup-*.sql
```

### 2. Desinstalar manteniendo los datos

```bash
# Desinstalar solo el release (mantiene PVCs)
helm uninstall aurora-gov --namespace aurora-gov

# Los PVCs permanecen para futura reinstalación
kubectl get pvc -n aurora-gov
```

### 3. Reinstalar con datos existentes (si es necesario)

```bash
# Reinstalar usando los mismos PVCs
helm install aurora-gov ./helm/aurora-gov \
  --namespace aurora-gov \
  --values ./helm/aurora-gov/values-production.yaml
```

## 🛠️ Script de Desinstalación Automatizada

### Crear script de desinstalación

```bash
#!/bin/bash
# uninstall-aurora-gov.sh

NAMESPACE="${1:-aurora-gov}"
RELEASE="${2:-aurora-gov}"
BACKUP="${3:-false}"

echo "🗑️ Desinstalando Aurora Gov..."
echo "Namespace: $NAMESPACE"
echo "Release: $RELEASE"
echo "Backup: $BACKUP"

# Función para confirmar acción
confirm() {
    read -p "$1 (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Backup si se solicita
if [ "$BACKUP" = "true" ]; then
    echo "📦 Creando backup de la base de datos..."
    kubectl exec -n "$NAMESPACE" deployment/"$RELEASE"-postgresql -- \
        pg_dump -U postgres aurora_gov > "aurora-gov-backup-$(date +%Y%m%d-%H%M%S).sql"
    echo "✅ Backup creado"
fi

# Desinstalar release
echo "🚀 Desinstalando release de Helm..."
if helm uninstall "$RELEASE" --namespace "$NAMESPACE"; then
    echo "✅ Release desinstalado"
else
    echo "❌ Error al desinstalar release"
    exit 1
fi

# Preguntar sobre PVCs
if confirm "¿Eliminar PVCs (esto eliminará TODOS los datos)?"; then
    echo "💾 Eliminando PVCs..."
    kubectl delete pvc -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE"
    echo "✅ PVCs eliminados"
fi

# Preguntar sobre namespace
if confirm "¿Eliminar el namespace completo?"; then
    echo "🗂️ Eliminando namespace..."
    kubectl delete namespace "$NAMESPACE"
    echo "✅ Namespace eliminado"
fi

echo "🎉 Desinstalación completada"
```

### Usar el script

```bash
# Hacer ejecutable
chmod +x uninstall-aurora-gov.sh

# Desinstalación básica
./uninstall-aurora-gov.sh

# Con backup
./uninstall-aurora-gov.sh aurora-gov aurora-gov true

# Namespace específico
./uninstall-aurora-gov.sh mi-namespace mi-release true
```

## 🔍 Verificación de Desinstalación

### 1. Verificar que no quedan recursos

```bash
# Verificar releases de Helm
helm list --all-namespaces | grep aurora-gov

# Verificar pods
kubectl get pods --all-namespaces | grep aurora-gov

# Verificar services
kubectl get svc --all-namespaces | grep aurora-gov

# Verificar ingress
kubectl get ingress --all-namespaces | grep aurora-gov

# Verificar PVCs
kubectl get pvc --all-namespaces | grep aurora-gov

# Verificar PVs huérfanos
kubectl get pv | grep aurora-gov
```

### 2. Verificar secrets y configmaps

```bash
# Verificar secrets
kubectl get secrets --all-namespaces | grep aurora-gov

# Verificar configmaps
kubectl get configmaps --all-namespaces | grep aurora-gov
```

### 3. Verificar certificados TLS

```bash
# Verificar certificados (si usas cert-manager)
kubectl get certificates --all-namespaces | grep aurora-gov

# Verificar secrets de TLS
kubectl get secrets --all-namespaces | grep tls | grep aurora-gov
```

## 🚨 Casos Especiales

### 1. Release en estado "failed"

```bash
# Si el release está en estado failed
helm uninstall aurora-gov --namespace aurora-gov --no-hooks

# O forzar eliminación
kubectl delete all -n aurora-gov -l app.kubernetes.io/instance=aurora-gov
```

### 2. Recursos que no se eliminan

```bash
# Forzar eliminación de pods
kubectl delete pods -n aurora-gov --force --grace-period=0

# Forzar eliminación de PVCs
kubectl patch pvc -n aurora-gov <pvc-name> -p '{"metadata":{"finalizers":null}}'

# Forzar eliminación de namespace
kubectl patch namespace aurora-gov -p '{"metadata":{"finalizers":null}}' --type=merge
```

### 3. Limpiar recursos huérfanos

```bash
# Buscar recursos huérfanos
kubectl api-resources --verbs=list --namespaced -o name | \
  xargs -n 1 kubectl get --show-kind --ignore-not-found -n aurora-gov

# Eliminar recursos específicos
kubectl delete <resource-type> -n aurora-gov <resource-name>
```

## 📋 Checklist de Desinstalación

### Antes de desinstalar:
- [ ] Hacer backup de datos importantes
- [ ] Verificar que no hay procesos críticos corriendo
- [ ] Notificar a usuarios sobre el downtime
- [ ] Documentar configuración actual

### Durante la desinstalación:
- [ ] Desinstalar release de Helm
- [ ] Verificar que pods se eliminaron
- [ ] Decidir sobre PVCs (mantener o eliminar)
- [ ] Limpiar secrets y configmaps
- [ ] Eliminar namespace si es necesario

### Después de la desinstalación:
- [ ] Verificar que no quedan recursos
- [ ] Confirmar que PVs huérfanos se limpiaron
- [ ] Verificar que certificados TLS se eliminaron
- [ ] Documentar el proceso para futuras referencias

## 🔄 Reinstalación después de Desinstalación

### 1. Reinstalación limpia (sin datos)

```bash
# Asegurar que todo está limpio
kubectl delete namespace aurora-gov

# Reinstalar desde cero
helm install aurora-gov ./helm/aurora-gov \
  --namespace aurora-gov \
  --create-namespace \
  --values ./helm/aurora-gov/values-production.yaml
```

### 2. Reinstalación con datos existentes

```bash
# Si mantuviste los PVCs
helm install aurora-gov ./helm/aurora-gov \
  --namespace aurora-gov \
  --values ./helm/aurora-gov/values-production.yaml
```

### 3. Restaurar desde backup

```bash
# Después de reinstalar, restaurar datos
kubectl exec -i -n aurora-gov deployment/aurora-gov-postgresql -- \
  psql -U postgres aurora_gov < aurora-gov-backup-20240101.sql
```

## 🆘 Solución de Problemas

### Namespace stuck en "Terminating"

```bash
# Ver qué recursos están bloqueando
kubectl api-resources --verbs=list --namespaced -o name | \
  xargs -n 1 kubectl get --show-kind --ignore-not-found -n aurora-gov

# Forzar eliminación del namespace
kubectl get namespace aurora-gov -o json | \
  jq '.spec = {"finalizers":[]}' | \
  kubectl replace --raw /api/v1/namespaces/aurora-gov/finalize -f -
```

### PVC stuck en "Terminating"

```bash
# Remover finalizers
kubectl patch pvc -n aurora-gov <pvc-name> -p '{"metadata":{"finalizers":null}}'

# O editar directamente
kubectl edit pvc -n aurora-gov <pvc-name>
# Eliminar la sección finalizers
```

### Recursos con finalizers

```bash
# Ver finalizers
kubectl get <resource> -n aurora-gov <name> -o yaml | grep finalizers -A 5

# Remover finalizers
kubectl patch <resource> -n aurora-gov <name> -p '{"metadata":{"finalizers":null}}'
```

## 📞 Contacto para Soporte

Si tienes problemas durante la desinstalación:

- **Email:** p.delgado@aurora.ong
- **Incluir:** Logs de error, configuración utilizada, pasos realizados
- **Adjuntar:** Output de `kubectl get all -n aurora-gov`