# 📋 Pasos de Deployment con Aurora Gov Helm Chart

Esta guía describe paso a paso todo lo que ocurre cuando despliegas Aurora Gov usando el Helm chart.

## 🚀 Pasos del Deployment

### 1. **Pre-requisitos y Validación**
- [ ] Verificar que Helm está instalado (`helm version`)
- [ ] Verificar conectividad al cluster (`kubectl cluster-info`)
- [ ] Verificar que el namespace existe o se puede crear
- [ ] Validar el chart con `helm lint`
- [ ] Verificar recursos disponibles en el cluster

### 2. **Preparación de Secrets**
- [ ] **Registry Secret**: Crear credenciales para `registry.weychafe.nicher.cl`
  ```bash
  kubectl create secret docker-registry weychafe-registry-secret \
    --docker-server=registry.weychafe.nicher.cl \
    --docker-username=<usuario> \
    --docker-password=<password>
  ```
- [ ] **Application Secrets**: Helm genera automáticamente:
  - `secret-key-base`: Clave secreta de Phoenix (64 caracteres aleatorios)
  - `postgres-password`: Password de PostgreSQL (16 caracteres aleatorios)
  - `projector-database-url`: URL de conexión para la BD de proyecciones
  - `eventstore-database-url`: URL de conexión para el event store

### 3. **Creación de Namespace**
- [ ] Crear namespace si no existe: `kubectl create namespace aurora-gov`
- [ ] Aplicar labels al namespace para organización

### 4. **Deployment de PostgreSQL (Base de Datos)**

#### 4.1 **StatefulSet de PostgreSQL**
- [ ] Crear StatefulSet `aurora-gov-postgresql`
- [ ] Configurar imagen: `postgres:15-alpine`
- [ ] Configurar variables de entorno:
  - `POSTGRES_PASSWORD`: Desde secret
  - `POSTGRES_DB`: `aurora_gov`
  - `PGDATA`: `/var/lib/postgresql/data/pgdata`
- [ ] Configurar recursos:
  - CPU: 250m request, 1000m limit
  - Memory: 512Mi request, 1Gi limit
- [ ] Configurar health checks (liveness/readiness probes)

#### 4.2 **Persistent Volume Claim (PVC)**
- [ ] Crear PVC para datos de PostgreSQL
- [ ] Tamaño: 10Gi (configurable)
- [ ] Access Mode: ReadWriteOnce
- [ ] Storage Class: Por defecto del cluster

#### 4.3 **Service de PostgreSQL**
- [ ] Crear service `aurora-gov-postgresql-service`
- [ ] Tipo: ClusterIP
- [ ] Puerto: 5432
- [ ] Selector: pods de PostgreSQL

### 5. **Deployment de la Aplicación Aurora Gov**

#### 5.1 **Deployment Principal**
- [ ] Crear Deployment `aurora-gov`
- [ ] Configurar imagen: `registry.weychafe.nicher.cl/aurora_gov:0.1.0`
- [ ] Configurar imagePullSecrets para registry privado
- [ ] Configurar réplicas: 1 (configurable)
- [ ] Configurar recursos:
  - CPU: 200m request, 500m limit
  - Memory: 256Mi request, 512Mi limit

#### 5.2 **Variables de Entorno**
- [ ] `PHX_SERVER=true`: Habilitar servidor Phoenix
- [ ] `PORT=4000`: Puerto de la aplicación
- [ ] `PHX_HOST=gov.aurora.ong`: Host público
- [ ] `SECRET_KEY_BASE`: Desde secret (para sesiones)
- [ ] `PROJECTOR_DATABASE_URL`: URL de BD de proyecciones
- [ ] `EVENTSTORE_DATABASE_URL`: URL de BD de eventos

#### 5.3 **Health Checks**
- [ ] **Liveness Probe**: HTTP GET a `/` cada 10s
- [ ] **Readiness Probe**: HTTP GET a `/` cada 5s
- [ ] Configurar timeouts y reintentos

#### 5.4 **Security Context**
- [ ] Ejecutar como usuario no-root (UID 1000)
- [ ] Eliminar capabilities innecesarias
- [ ] Configurar fsGroup para volúmenes

### 6. **Servicios de Red**

#### 6.1 **Service de la Aplicación**
- [ ] Crear service `aurora-gov`
- [ ] Tipo: ClusterIP
- [ ] Puerto: 80 → 4000 (mapeo)
- [ ] Selector: pods de Aurora Gov

#### 6.2 **Ingress (Acceso Externo)**
- [ ] Crear Ingress `aurora-gov`
- [ ] Host: `gov.aurora.ong`
- [ ] Ingress Class: `public`
- [ ] Configurar anotaciones:
  - `cert-manager.io/cluster-issuer`: Para certificados TLS
  - `nginx.ingress.kubernetes.io/force-ssl-redirect`: Forzar HTTPS
  - `nginx.ingress.kubernetes.io/proxy-read-timeout`: Timeout de 120s

#### 6.3 **Certificados TLS**
- [ ] cert-manager genera certificado automáticamente
- [ ] Secret TLS: `aurora-gov-tls`
- [ ] Certificado válido para `gov.aurora.ong`

### 7. **Configuración y Secrets**

#### 7.1 **ConfigMap (Opcional)**
- [ ] Crear ConfigMap para configuración adicional
- [ ] Variables de configuración no sensibles

#### 7.2 **ServiceAccount**
- [ ] Crear ServiceAccount `aurora-gov`
- [ ] Configurar imagePullSecrets
- [ ] Deshabilitar automount de token por seguridad

### 8. **Inicialización de la Base de Datos**

#### 8.1 **Esperar a PostgreSQL**
- [ ] Verificar que PostgreSQL está listo
- [ ] Probes de readiness confirman disponibilidad

#### 8.2 **Inicialización Automática**
- [ ] Aurora Gov detecta BD vacía
- [ ] Ejecuta migraciones automáticamente:
  - Crear tablas de proyecciones
  - Crear tablas de event store
  - Aplicar esquemas iniciales

### 9. **Verificación del Deployment**

#### 9.1 **Pods**
- [ ] Verificar que pods están en estado `Running`
- [ ] Verificar que health checks pasan
- [ ] Verificar logs sin errores críticos

#### 9.2 **Servicios**
- [ ] Verificar que services tienen endpoints
- [ ] Verificar conectividad interna

#### 9.3 **Ingress**
- [ ] Verificar que Ingress tiene IP asignada
- [ ] Verificar que certificado TLS está válido
- [ ] Verificar acceso externo funciona

### 10. **Configuraciones Opcionales**

#### 10.1 **Horizontal Pod Autoscaler (HPA)**
- [ ] Crear HPA si está habilitado
- [ ] Configurar métricas de CPU/memoria
- [ ] Configurar min/max réplicas

#### 10.2 **Pod Disruption Budget (PDB)**
- [ ] Crear PDB si está habilitado
- [ ] Configurar mínimo de pods disponibles

#### 10.3 **Network Policies**
- [ ] Crear Network Policies si están habilitadas
- [ ] Configurar reglas de ingress/egress
- [ ] Restringir tráfico entre pods

## 🔄 Flujo Temporal del Deployment

### Fase 1: Preparación (0-30s)
1. Helm valida el chart y valores
2. Genera manifests de Kubernetes
3. Crea namespace si no existe
4. Crea secrets automáticamente

### Fase 2: Base de Datos (30s-2m)
1. Crea PVC para PostgreSQL
2. Inicia StatefulSet de PostgreSQL
3. Espera a que PostgreSQL esté listo
4. Crea service de PostgreSQL

### Fase 3: Aplicación (2m-4m)
1. Crea Deployment de Aurora Gov
2. Descarga imagen del registry privado
3. Inicia contenedor de la aplicación
4. Ejecuta health checks

### Fase 4: Red y Acceso (4m-6m)
1. Crea service de la aplicación
2. Crea Ingress para acceso externo
3. cert-manager genera certificado TLS
4. Configura DNS y routing

### Fase 5: Inicialización (6m-8m)
1. Aurora Gov se conecta a PostgreSQL
2. Ejecuta migraciones de BD
3. Inicializa event store
4. Aplicación lista para recibir tráfico

## 📊 Recursos Creados

### Workloads
- **1 Deployment**: `aurora-gov` (aplicación principal)
- **1 StatefulSet**: `aurora-gov-postgresql` (base de datos)

### Networking
- **2 Services**: 
  - `aurora-gov` (aplicación)
  - `aurora-gov-postgresql-service` (base de datos)
- **1 Ingress**: `aurora-gov` (acceso externo)

### Storage
- **1 PVC**: Para datos de PostgreSQL
- **1 PV**: Asignado automáticamente por storage class

### Configuration
- **1 Secret**: `aurora-gov-secrets` (credenciales y configuración)
- **1 ConfigMap**: `aurora-gov-config` (configuración opcional)
- **1 ServiceAccount**: `aurora-gov` (identidad de pods)

### Security
- **1 Registry Secret**: `weychafe-registry-secret` (acceso a registry)
- **1 TLS Secret**: `aurora-gov-tls` (certificado HTTPS)

## 🔍 Comandos de Monitoreo

### Durante el Deployment
```bash
# Monitorear progreso general
kubectl get all -n aurora-gov -w

# Monitorear pods específicamente
kubectl get pods -n aurora-gov -w

# Ver eventos en tiempo real
kubectl get events -n aurora-gov --sort-by='.lastTimestamp' -w

# Ver logs de la aplicación
kubectl logs -n aurora-gov -l app.kubernetes.io/name=aurora-gov -f
```

### Verificación Post-Deployment
```bash
# Estado general
helm status aurora-gov -n aurora-gov

# Verificar pods
kubectl get pods -n aurora-gov

# Verificar servicios
kubectl get svc -n aurora-gov

# Verificar ingress
kubectl get ingress -n aurora-gov

# Test de conectividad
curl -k https://gov.aurora.ong
```

## ⚠️ Puntos Críticos de Fallo

### 1. **Registry Authentication**
- **Problema**: No se puede descargar la imagen
- **Solución**: Verificar registry secret y credenciales

### 2. **Storage Provisioning**
- **Problema**: PVC queda en estado Pending
- **Solución**: Verificar storage class y disponibilidad

### 3. **Database Connection**
- **Problema**: App no puede conectar a PostgreSQL
- **Solución**: Verificar service y URLs de conexión

### 4. **TLS Certificate**
- **Problema**: Certificado no se genera
- **Solución**: Verificar cert-manager y DNS

### 5. **Resource Limits**
- **Problema**: Pods no se programan por falta de recursos
- **Solución**: Ajustar requests/limits o escalar cluster

## 🎯 Criterios de Éxito

El deployment es exitoso cuando:
- [ ] Todos los pods están en estado `Running`
- [ ] Health checks pasan consistentemente
- [ ] Servicios tienen endpoints válidos
- [ ] Ingress tiene IP asignada
- [ ] Certificado TLS está válido
- [ ] Aplicación responde en `https://gov.aurora.ong`
- [ ] Base de datos acepta conexiones
- [ ] Logs no muestran errores críticos

## 📞 Soporte

Si algún paso falla:
1. Usar scripts de debug: `./helm/debug-scripts/troubleshoot.sh`
2. Revisar logs detallados
3. Contactar: p.delgado@aurora.ong