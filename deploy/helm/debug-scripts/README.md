# 🔧 Scripts de Debug para Aurora Gov

Esta carpeta contiene scripts útiles para debuggear la instalación de Aurora Gov con Helm.

## 📁 Scripts Disponibles

### 1. `validate-chart.sh`
**Propósito:** Validar el chart antes de la instalación
**Uso:**
```bash
./validate-chart.sh [values-file]
```

**Funciones:**
- ✅ Verifica dependencias (helm, kubectl)
- ✅ Valida estructura del chart
- ✅ Ejecuta helm lint
- ✅ Renderiza templates
- ✅ Valida YAML generado
- ✅ Verifica recursos del cluster
- ✅ Simula instalación (dry-run)

**Ejemplo:**
```bash
# Validación básica
./validate-chart.sh

# Validación con valores de producción
./validate-chart.sh values-production.yaml
```

### 2. `monitor-installation.sh`
**Propósito:** Monitorear la instalación en tiempo real
**Uso:**
```bash
./monitor-installation.sh [namespace] [release-name]
```

**Funciones:**
- 🔍 Monitoreo en tiempo real de pods, services, ingress
- 📊 Barra de progreso visual
- 📋 Eventos recientes
- ⏰ Timeout configurable
- 🎉 Detección automática de instalación completa

**Ejemplo:**
```bash
# Monitoreo básico
./monitor-installation.sh

# Monitoreo específico
./monitor-installation.sh aurora-gov-prod aurora-gov
```

### 3. `troubleshoot.sh`
**Propósito:** Recopilar información completa para troubleshooting
**Uso:**
```bash
./troubleshoot.sh [namespace] [release-name]
```

**Funciones:**
- 📦 Información completa del cluster y release
- 📝 Logs de todos los pods
- 🔍 Descripciones detalladas de recursos
- 📋 Eventos y errores
- 💾 Información de storage y red
- 📊 Métricas de recursos
- 🗜️ Compresión automática de resultados

**Ejemplo:**
```bash
# Troubleshooting completo
./troubleshoot.sh

# Para namespace específico
./troubleshoot.sh aurora-gov-prod aurora-gov
```

## 🚀 Flujo de Trabajo Recomendado

### 1. Pre-instalación
```bash
# Validar el chart
./validate-chart.sh values-production.yaml

# Si hay errores, corregir y volver a validar
```

### 2. Durante la instalación
```bash
# En una terminal, instalar
helm install aurora-gov ../aurora-gov --namespace aurora-gov --create-namespace

# En otra terminal, monitorear
./monitor-installation.sh aurora-gov aurora-gov
```

### 3. Post-instalación (si hay problemas)
```bash
# Recopilar información de debug
./troubleshoot.sh aurora-gov aurora-gov

# Analizar resultados en el directorio generado
```

## 🔍 Casos de Uso Específicos

### Problema: Pods en CrashLoopBackOff
```bash
# 1. Recopilar información
./troubleshoot.sh

# 2. Revisar logs específicos
kubectl logs -n aurora-gov -l app.kubernetes.io/name=aurora-gov --previous

# 3. Verificar secrets
kubectl get secret -n aurora-gov aurora-gov-secrets -o yaml
```

### Problema: Base de datos no conecta
```bash
# 1. Verificar pods de PostgreSQL
kubectl get pods -n aurora-gov -l app.kubernetes.io/component=postgresql

# 2. Verificar service
kubectl get svc -n aurora-gov -l app.kubernetes.io/component=postgresql

# 3. Test de conectividad
kubectl run -it --rm pg-test --image=postgres:15-alpine --restart=Never -- \
  psql -h aurora-gov-postgresql-service -U postgres -d aurora_gov
```

### Problema: Ingress no funciona
```bash
# 1. Verificar ingress controller
kubectl get pods -n ingress-nginx

# 2. Verificar certificados
kubectl get certificate -n aurora-gov

# 3. Verificar DNS
nslookup gov.aurora.ong
```

## 🛠️ Personalización de Scripts

### Variables de Entorno
```bash
# Timeout para monitoreo (segundos)
export MONITOR_TIMEOUT=900

# Directorio de output para troubleshooting
export DEBUG_OUTPUT_DIR="/custom/path"

# Namespace por defecto
export DEFAULT_NAMESPACE="aurora-gov"
```

### Modificar Scripts
Los scripts están diseñados para ser modificables. Puedes:

1. **Cambiar timeouts:** Editar variable `TIMEOUT` en `monitor-installation.sh`
2. **Añadir checks:** Agregar validaciones en `validate-chart.sh`
3. **Personalizar output:** Modificar formato en `troubleshoot.sh`

## 📋 Checklist de Debug

### Pre-instalación
- [ ] Chart lint pasa sin errores
- [ ] Templates se renderizan correctamente
- [ ] Dry-run funciona
- [ ] Cluster tiene recursos suficientes
- [ ] Storage classes disponibles
- [ ] Ingress controller funcionando

### Durante instalación
- [ ] Pods se crean correctamente
- [ ] Services tienen endpoints
- [ ] PVCs se vinculan a PVs
- [ ] Secrets se crean con datos válidos
- [ ] No hay eventos de error

### Post-instalación
- [ ] Todos los pods están Running
- [ ] Health checks pasan
- [ ] Ingress tiene IP asignada
- [ ] Aplicación responde correctamente
- [ ] Base de datos acepta conexiones

## 🆘 Obtener Ayuda

Si los scripts no resuelven tu problema:

1. **Ejecutar troubleshoot completo:**
```bash
./troubleshoot.sh
```

2. **Enviar información al soporte:**
- Archivo comprimido generado por troubleshoot.sh
- Descripción del problema
- Pasos para reproducir
- Configuración específica utilizada

3. **Contacto:**
- Email: p.delgado@aurora.ong
- Incluir: versión de Kubernetes, Helm, y configuración del cluster

## 📚 Recursos Adicionales

- [Guía de Debug Completa](../debug-guide.md)
- [Ejemplos de Instalación](../install-examples.md)
- [Documentación del Chart](../aurora-gov/README.md)
- [Helm Debugging](https://helm.sh/docs/chart_best_practices/debugging/)
- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug-application-cluster/)