# 🔐 Guía de Secrets para Registry Privado - Aurora Gov

Esta guía explica cómo configurar las credenciales necesarias para descargar imágenes del registry privado `registry.weychafe.nicher.cl`.

## 🎯 Problema Identificado

El chart de Aurora Gov usa la imagen:
```
registry.weychafe.nicher.cl/aurora_gov:0
```

Este es un **registry privado** que requiere autenticación para descargar imágenes.

## 🔑 Tipos de Secrets para Registry

### 1. Docker Registry Secret (Recomendado)

```bash
# Crear secret con credenciales del registry
kubectl create secret docker-registry weychafe-registry-secret \
  --namespace aurora-gov \
  --docker-server=registry.weychafe.nicher.cl \
  --docker-username=nicher-weychafe \
  --docker-password=cVEAmaoo0XT7jDDiROX4 \
  --docker-email=p.delgado@aurora.ong
```

### 2. Desde archivo .dockercfg

```bash
# Si tienes un archivo .dockercfg
kubectl create secret generic weychafe-registry-secret \
  --namespace aurora-gov \
  --from-file=.dockercfg=<path-to-.dockercfg> \
  --type=kubernetes.io/dockercfg
```

### 3. Desde archivo config.json de Docker

```bash
# Si tienes config.json de Docker
kubectl create secret generic weychafe-registry-secret \
  --namespace aurora-gov \
  --from-file=.dockerconfigjson=<path-to-config.json> \
  --type=kubernetes.io/dockerconfigjson
```

## 🛠️ Configuración en el Chart de Helm

### Opción 1: Configurar en values.yaml

```yaml
# En values.yaml o values-production.yaml
global:
  imagePullSecrets:
    - name: weychafe-registry-secret

# O específicamente para la aplicación
app:
  image:
    pullSecrets:
      - name: weychafe-registry-secret
```

### Opción 2: Usar imagePullSecrets existente

```yaml
# Si ya tienes el secret creado
global:
  imagePullSecrets:
    - name: weychafe-registry-secret
```

## 📝 Script para Crear Secret

### Crear script automatizado

```bash
#!/bin/bash
# create-registry-secret.sh

NAMESPACE="${1:-aurora-gov}"
SECRET_NAME="${2:-weychafe-registry-secret}"
REGISTRY_SERVER="registry.weychafe.nicher.cl"

echo "🔐 Creando secret para registry privado"
echo "Namespace: $NAMESPACE"
echo "Secret: $SECRET_NAME"
echo "Registry: $REGISTRY_SERVER"

# Solicitar credenciales
read -p "Usuario del registry: " DOCKER_USERNAME
read -s -p "Password del registry: " DOCKER_PASSWORD
echo
read -p "Email (opcional): " DOCKER_EMAIL

# Crear namespace si no existe
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Crear secret
kubectl create secret docker-registry "$SECRET_NAME" \
  --namespace="$NAMESPACE" \
  --docker-server="$REGISTRY_SERVER" \
  --docker-username="$DOCKER_USERNAME" \
  --docker-password="$DOCKER_PASSWORD" \
  --docker-email="$DOCKER_EMAIL"

if [ $? -eq 0 ]; then
    echo "✅ Secret creado exitosamente"
    
    # Verificar secret
    kubectl get secret "$SECRET_NAME" -n "$NAMESPACE"
    
    echo ""
    echo "💡 Para usar en Helm:"
    echo "helm install aurora-gov ./helm/aurora-gov \\"
    echo "  --namespace $NAMESPACE \\"
    echo "  --set global.imagePullSecrets[0].name=$SECRET_NAME"
else
    echo "❌ Error al crear secret"
    exit 1
fi
```

## 🔧 Actualizar Chart para Usar Secrets

### 1. Modificar values.yaml

```yaml
# Agregar configuración de imagePullSecrets
global:
  imageRegistry: ""
  imagePullSecrets:
    - name: weychafe-registry-secret
  storageClass: ""
```

### 2. Actualizar template de deployment

El template ya está configurado para usar `global.imagePullSecrets`:

```yaml
# En templates/deployment.yaml (ya incluido)
spec:
  {{- with .Values.global.imagePullSecrets }}
  imagePullSecrets:
    {{- toYaml . | nindent 8 }}
  {{- end }}
```

## 🚀 Instalación con Registry Secret

### Método 1: Crear secret primero

```bash
# 1. Crear secret
kubectl create secret docker-registry weychafe-registry-secret \
  --namespace aurora-gov \
  --docker-server=registry.weychafe.nicher.cl \
  --docker-username=<usuario> \
  --docker-password=<password> \
  --docker-email=<email>

# 2. Instalar con secret
helm install aurora-gov ./helm/aurora-gov \
  --namespace aurora-gov \
  --create-namespace \
  --set global.imagePullSecrets[0].name=weychafe-registry-secret
```

### Método 2: Configurar en values file

```yaml
# En values-production.yaml
global:
  imagePullSecrets:
    - name: weychafe-registry-secret

app:
  image:
    registry: registry.weychafe.nicher.cl
    repository: aurora_gov
    tag: "latest"  # o la versión específica
```

```bash
# Instalar con values file
helm install aurora-gov ./helm/aurora-gov \
  --namespace aurora-gov \
  --create-namespace \
  --values ./helm/aurora-gov/values-production.yaml
```

## 🔍 Verificar Configuración

### 1. Verificar que el secret existe

```bash
kubectl get secrets -n aurora-gov
kubectl describe secret weychafe-registry-secret -n aurora-gov
```

### 2. Verificar que el pod usa el secret

```bash
# Ver configuración del pod
kubectl describe pod -n aurora-gov -l app.kubernetes.io/name=aurora-gov

# Buscar sección "Image Pull Secrets"
```

### 3. Test de descarga de imagen

```bash
# Crear pod de test
kubectl run test-image \
  --image=registry.weychafe.nicher.cl/aurora_gov:0 \
  --namespace=aurora-gov \
  --dry-run=client -o yaml > test-pod.yaml

# Agregar imagePullSecrets al YAML
echo "  imagePullSecrets:" >> test-pod.yaml
echo "  - name: weychafe-registry-secret" >> test-pod.yaml

# Aplicar test
kubectl apply -f test-pod.yaml

# Verificar que descarga correctamente
kubectl get pod test-image -n aurora-gov
kubectl describe pod test-image -n aurora-gov
```

## 🚨 Troubleshooting de Registry

### Error: "ImagePullBackOff"

```bash
# Ver detalles del error
kubectl describe pod -n aurora-gov <pod-name>

# Buscar en eventos:
# - "Failed to pull image"
# - "unauthorized: authentication required"
# - "pull access denied"
```

**Soluciones:**
1. Verificar credenciales del secret
2. Verificar que el secret está en el namespace correcto
3. Verificar que imagePullSecrets está configurado

### Error: "ErrImagePull"

```bash
# Verificar conectividad al registry
nslookup registry.weychafe.nicher.cl

# Test manual de login
docker login registry.weychafe.nicher.cl
```

### Verificar contenido del secret

```bash
# Ver contenido del secret (base64 encoded)
kubectl get secret weychafe-registry-secret -n aurora-gov -o yaml

# Decodificar contenido
kubectl get secret weychafe-registry-secret -n aurora-gov \
  -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq
```

## 📋 Checklist de Registry Secret

- [ ] Registry server correcto: `registry.weychafe.nicher.cl`
- [ ] Credenciales válidas (usuario/password)
- [ ] Secret creado en namespace correcto
- [ ] imagePullSecrets configurado en values.yaml
- [ ] Template de deployment incluye imagePullSecrets
- [ ] Pod puede descargar la imagen exitosamente

## 🔄 Actualizar Secret Existente

### Recrear secret con nuevas credenciales

```bash
# Eliminar secret existente
kubectl delete secret weychafe-registry-secret -n aurora-gov

# Crear nuevo secret
kubectl create secret docker-registry weychafe-registry-secret \
  --namespace aurora-gov \
  --docker-server=registry.weychafe.nicher.cl \
  --docker-username=<nuevo-usuario> \
  --docker-password=<nuevo-password> \
  --docker-email=<email>

# Reiniciar deployment para usar nuevo secret
kubectl rollout restart deployment aurora-gov -n aurora-gov
```

## 🔐 Mejores Prácticas de Seguridad

### 1. Usar Service Account específico

```yaml
# Crear ServiceAccount con imagePullSecrets
apiVersion: v1
kind: ServiceAccount
metadata:
  name: aurora-gov-sa
  namespace: aurora-gov
imagePullSecrets:
- name: weychafe-registry-secret
```

### 2. Rotar credenciales regularmente

```bash
# Script para rotar credenciales
#!/bin/bash
# rotate-registry-secret.sh

NAMESPACE="aurora-gov"
SECRET_NAME="weychafe-registry-secret"

echo "🔄 Rotando credenciales del registry..."

# Backup del secret actual
kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o yaml > "backup-$SECRET_NAME-$(date +%Y%m%d).yaml"

# Crear nuevo secret
./create-registry-secret.sh "$NAMESPACE" "$SECRET_NAME"

# Reiniciar deployments
kubectl rollout restart deployment -n "$NAMESPACE"
```

### 3. Usar External Secrets Operator (Avanzado)

```yaml
# Para integrar con sistemas como HashiCorp Vault
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: weychafe-registry-secret
  namespace: aurora-gov
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: weychafe-registry-secret
    creationPolicy: Owner
    template:
      type: kubernetes.io/dockerconfigjson
  data:
  - secretKey: .dockerconfigjson
    remoteRef:
      key: registry-credentials
      property: dockerconfig
```

## 📞 Contacto para Credenciales

Si necesitas credenciales para el registry `registry.weychafe.nicher.cl`:

- **Contacto:** p.delgado@aurora.ong
- **Información necesaria:**
  - Propósito del acceso
  - Duración estimada
  - Entorno (desarrollo/producción)

## 💡 Alternativas

### 1. Usar registry público

```yaml
# Cambiar a registry público si está disponible
app:
  image:
    registry: docker.io  # o ghcr.io
    repository: aurora-org/aurora_gov
    tag: "latest"
```

### 2. Build local de la imagen

```bash
# Si tienes el código fuente
docker build -t aurora_gov:local .
docker tag aurora_gov:local registry.weychafe.nicher.cl/aurora_gov:local

# Usar imagen local
helm install aurora-gov ./helm/aurora-gov \
  --set app.image.tag=local \
  --set app.image.pullPolicy=Never
```