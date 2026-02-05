#!/bin/bash

# Script para crear secret de registry privado para Aurora Gov
# Uso: ./create-registry-secret.sh [namespace] [secret-name]

set -e

NAMESPACE="${1:-aurora-gov}"
SECRET_NAME="${2:-weychafe-registry-secret}"
REGISTRY_SERVER="registry.weychafe.nicher.cl"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔐 Creando Secret para Registry Privado${NC}"
echo "Registry: $REGISTRY_SERVER"
echo "Namespace: $NAMESPACE"
echo "Secret: $SECRET_NAME"
echo "=================================="

# Función para verificar dependencias
check_dependencies() {
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}❌ kubectl no está instalado${NC}"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}❌ No se puede conectar al cluster de Kubernetes${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Dependencias verificadas${NC}"
}

# Función para solicitar credenciales
get_credentials() {
    echo -e "\n${YELLOW}📝 Ingresa las credenciales del registry:${NC}"
    
    # Usuario
    while [ -z "$DOCKER_USERNAME" ]; do
        read -p "Usuario del registry: " DOCKER_USERNAME
        if [ -z "$DOCKER_USERNAME" ]; then
            echo -e "${RED}❌ El usuario es requerido${NC}"
        fi
    done
    
    # Password
    while [ -z "$DOCKER_PASSWORD" ]; do
        read -s -p "Password del registry: " DOCKER_PASSWORD
        echo
        if [ -z "$DOCKER_PASSWORD" ]; then
            echo -e "${RED}❌ El password es requerido${NC}"
        fi
    done
    
    # Email (opcional)
    read -p "Email (opcional): " DOCKER_EMAIL
    if [ -z "$DOCKER_EMAIL" ]; then
        DOCKER_EMAIL="noreply@aurora.ong"
    fi
    
    echo -e "${GREEN}✅ Credenciales obtenidas${NC}"
}

# Función para crear namespace si no existe
create_namespace() {
    if kubectl get namespace "$NAMESPACE" &>/dev/null; then
        echo -e "${GREEN}✅ Namespace '$NAMESPACE' ya existe${NC}"
    else
        echo -e "${BLUE}📁 Creando namespace '$NAMESPACE'...${NC}"
        if kubectl create namespace "$NAMESPACE"; then
            echo -e "${GREEN}✅ Namespace creado${NC}"
        else
            echo -e "${RED}❌ Error al crear namespace${NC}"
            exit 1
        fi
    fi
}

# Función para verificar si el secret ya existe
check_existing_secret() {
    if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &>/dev/null; then
        echo -e "${YELLOW}⚠️  Secret '$SECRET_NAME' ya existe en namespace '$NAMESPACE'${NC}"
        read -p "¿Reemplazar el secret existente? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}🗑️ Eliminando secret existente...${NC}"
            kubectl delete secret "$SECRET_NAME" -n "$NAMESPACE"
            echo -e "${GREEN}✅ Secret existente eliminado${NC}"
        else
            echo -e "${BLUE}ℹ️  Manteniendo secret existente${NC}"
            return 1
        fi
    fi
    return 0
}

# Función para crear el secret
create_secret() {
    echo -e "${BLUE}🔑 Creando secret de registry...${NC}"
    
    if kubectl create secret docker-registry "$SECRET_NAME" \
        --namespace="$NAMESPACE" \
        --docker-server="$REGISTRY_SERVER" \
        --docker-username="$DOCKER_USERNAME" \
        --docker-password="$DOCKER_PASSWORD" \
        --docker-email="$DOCKER_EMAIL"; then
        
        echo -e "${GREEN}✅ Secret creado exitosamente${NC}"
        return 0
    else
        echo -e "${RED}❌ Error al crear secret${NC}"
        return 1
    fi
}

# Función para verificar el secret
verify_secret() {
    echo -e "${BLUE}🔍 Verificando secret...${NC}"
    
    # Verificar que existe
    if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" &>/dev/null; then
        echo -e "${GREEN}✅ Secret existe${NC}"
        
        # Mostrar información básica
        kubectl get secret "$SECRET_NAME" -n "$NAMESPACE"
        
        # Verificar tipo
        SECRET_TYPE=$(kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.type}')
        if [ "$SECRET_TYPE" = "kubernetes.io/dockerconfigjson" ]; then
            echo -e "${GREEN}✅ Tipo de secret correcto${NC}"
        else
            echo -e "${YELLOW}⚠️  Tipo de secret: $SECRET_TYPE${NC}"
        fi
        
        # Verificar contenido (sin mostrar credenciales)
        if kubectl get secret "$SECRET_NAME" -n "$NAMESPACE" -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq . &>/dev/null; then
            echo -e "${GREEN}✅ Contenido del secret válido${NC}"
        else
            echo -e "${RED}❌ Contenido del secret inválido${NC}"
            return 1
        fi
        
        return 0
    else
        echo -e "${RED}❌ Secret no encontrado${NC}"
        return 1
    fi
}

# Función para test de conectividad (opcional)
test_registry_connectivity() {
    echo -e "${BLUE}🌐 Probando conectividad al registry...${NC}"
    
    if command -v nslookup &> /dev/null; then
        if nslookup "$REGISTRY_SERVER" &>/dev/null; then
            echo -e "${GREEN}✅ Registry es accesible por DNS${NC}"
        else
            echo -e "${YELLOW}⚠️  Registry no es accesible por DNS${NC}"
        fi
    fi
    
    if command -v curl &> /dev/null; then
        if curl -s --connect-timeout 5 "https://$REGISTRY_SERVER" &>/dev/null; then
            echo -e "${GREEN}✅ Registry responde a HTTPS${NC}"
        else
            echo -e "${YELLOW}⚠️  Registry no responde a HTTPS${NC}"
        fi
    fi
}

# Función para crear pod de test
create_test_pod() {
    echo -e "${BLUE}🧪 ¿Crear pod de test para verificar descarga de imagen? (y/N): ${NC}"
    read -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🚀 Creando pod de test...${NC}"
        
        cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: registry-test-pod
  namespace: $NAMESPACE
  labels:
    app: registry-test
spec:
  restartPolicy: Never
  imagePullSecrets:
  - name: $SECRET_NAME
  containers:
  - name: test
    image: $REGISTRY_SERVER/aurora_gov:0
    command: ["echo", "Test successful"]
    resources:
      requests:
        cpu: 10m
        memory: 16Mi
      limits:
        cpu: 50m
        memory: 32Mi
EOF
        
        echo -e "${BLUE}⏳ Esperando a que el pod se cree...${NC}"
        sleep 5
        
        # Verificar estado del pod
        POD_STATUS=$(kubectl get pod registry-test-pod -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
        
        case $POD_STATUS in
            "Succeeded"|"Running")
                echo -e "${GREEN}✅ Test exitoso - La imagen se descargó correctamente${NC}"
                ;;
            "Pending")
                echo -e "${YELLOW}⏳ Pod en estado Pending - Verificando eventos...${NC}"
                kubectl describe pod registry-test-pod -n "$NAMESPACE" | grep -A 10 "Events:"
                ;;
            "Failed")
                echo -e "${RED}❌ Test falló - Verificando eventos...${NC}"
                kubectl describe pod registry-test-pod -n "$NAMESPACE" | grep -A 10 "Events:"
                ;;
            *)
                echo -e "${YELLOW}❓ Estado del pod: $POD_STATUS${NC}"
                kubectl describe pod registry-test-pod -n "$NAMESPACE" | grep -A 10 "Events:"
                ;;
        esac
        
        # Limpiar pod de test
        echo -e "${BLUE}🧹 Limpiando pod de test...${NC}"
        kubectl delete pod registry-test-pod -n "$NAMESPACE" --ignore-not-found=true
    fi
}

# Función para mostrar instrucciones de uso
show_usage_instructions() {
    echo -e "\n${BLUE}📋 Instrucciones de uso:${NC}"
    echo
    echo -e "${YELLOW}1. Para usar en instalación de Helm:${NC}"
    echo "   helm install aurora-gov ./helm/aurora-gov \\"
    echo "     --namespace $NAMESPACE \\"
    echo "     --create-namespace \\"
    echo "     --set global.imagePullSecrets[0].name=$SECRET_NAME"
    echo
    echo -e "${YELLOW}2. Para configurar en values.yaml:${NC}"
    echo "   global:"
    echo "     imagePullSecrets:"
    echo "       - name: $SECRET_NAME"
    echo
    echo -e "${YELLOW}3. Para verificar que funciona:${NC}"
    echo "   kubectl describe pod -n $NAMESPACE -l app.kubernetes.io/name=aurora-gov"
    echo "   # Buscar 'Image Pull Secrets: $SECRET_NAME'"
    echo
    echo -e "${YELLOW}4. Para actualizar el secret:${NC}"
    echo "   ./create-registry-secret.sh $NAMESPACE $SECRET_NAME"
}

# Función principal
main() {
    echo -e "${BLUE}Iniciando creación de secret...${NC}"
    
    # Verificar dependencias
    check_dependencies
    
    # Crear namespace
    create_namespace
    
    # Verificar secret existente
    if ! check_existing_secret; then
        echo -e "${BLUE}ℹ️  Usando secret existente${NC}"
        verify_secret
        show_usage_instructions
        return 0
    fi
    
    # Obtener credenciales
    get_credentials
    
    # Test de conectividad (opcional)
    test_registry_connectivity
    
    # Crear secret
    if create_secret; then
        # Verificar secret
        if verify_secret; then
            # Test opcional con pod
            create_test_pod
            
            # Mostrar instrucciones
            show_usage_instructions
            
            echo -e "\n${GREEN}🎉 Secret de registry creado exitosamente${NC}"
        else
            echo -e "${RED}❌ Error en la verificación del secret${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ Error al crear secret${NC}"
        exit 1
    fi
}

# Función de ayuda
show_help() {
    echo "Uso: $0 [namespace] [secret-name]"
    echo
    echo "Parámetros:"
    echo "  namespace    Namespace donde crear el secret (default: aurora-gov)"
    echo "  secret-name  Nombre del secret (default: weychafe-registry-secret)"
    echo
    echo "Ejemplos:"
    echo "  $0                                    # Usar valores por defecto"
    echo "  $0 aurora-gov-prod                   # Namespace específico"
    echo "  $0 aurora-gov-prod my-registry-secret # Namespace y nombre específicos"
    echo
    echo "Registry: $REGISTRY_SERVER"
}

# Verificar argumentos
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Ejecutar función principal
main "$@"