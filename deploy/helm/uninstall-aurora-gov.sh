#!/bin/bash

# Script para desinstalar Aurora Gov de forma segura
# Uso: ./uninstall-aurora-gov.sh [namespace] [release-name] [backup]

set -e

NAMESPACE="${1:-aurora-gov}"
RELEASE="${2:-aurora-gov}"
BACKUP="${3:-false}"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🗑️ Aurora Gov - Script de Desinstalación${NC}"
echo "Namespace: $NAMESPACE"
echo "Release: $RELEASE"
echo "Backup: $BACKUP"
echo "=================================="

# Función para mostrar timestamp
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Función para log con timestamp
log() {
    echo -e "[$(timestamp)] $1"
}

# Función para confirmar acción
confirm() {
    read -p "$1 (y/N): " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

# Función para verificar dependencias
check_dependencies() {
    log "${BLUE}Verificando dependencias...${NC}"
    
    if ! command -v helm &> /dev/null; then
        log "${RED}❌ Helm no está instalado${NC}"
        exit 1
    fi
    
    if ! command -v kubectl &> /dev/null; then
        log "${RED}❌ kubectl no está instalado${NC}"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        log "${RED}❌ No se puede conectar al cluster de Kubernetes${NC}"
        exit 1
    fi
    
    log "${GREEN}✅ Dependencias verificadas${NC}"
}

# Función para verificar que el release existe
check_release() {
    log "${BLUE}Verificando release...${NC}"
    
    if ! helm status "$RELEASE" -n "$NAMESPACE" &>/dev/null; then
        log "${YELLOW}⚠️  Release '$RELEASE' no encontrado en namespace '$NAMESPACE'${NC}"
        
        # Verificar si hay recursos huérfanos
        ORPHAN_RESOURCES=$(kubectl get all -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" --no-headers 2>/dev/null | wc -l)
        if [ "$ORPHAN_RESOURCES" -gt 0 ]; then
            log "${YELLOW}⚠️  Encontrados $ORPHAN_RESOURCES recursos huérfanos${NC}"
            if confirm "¿Limpiar recursos huérfanos?"; then
                kubectl delete all -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE"
                log "${GREEN}✅ Recursos huérfanos eliminados${NC}"
            fi
        fi
        return 1
    fi
    
    log "${GREEN}✅ Release encontrado${NC}"
    return 0
}

# Función para crear backup
create_backup() {
    if [ "$BACKUP" = "true" ]; then
        log "${BLUE}📦 Creando backup de la base de datos...${NC}"
        
        BACKUP_FILE="aurora-gov-backup-$(date +%Y%m%d-%H%M%S).sql"
        
        # Verificar que el pod de PostgreSQL existe
        PG_POD=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/component=postgresql" --no-headers 2>/dev/null | awk '{print $1}' | head -1)
        
        if [ -z "$PG_POD" ]; then
            log "${YELLOW}⚠️  Pod de PostgreSQL no encontrado, saltando backup${NC}"
            return 0
        fi
        
        # Crear backup
        if kubectl exec -n "$NAMESPACE" "$PG_POD" -- pg_dump -U postgres aurora_gov > "$BACKUP_FILE" 2>/dev/null; then
            log "${GREEN}✅ Backup creado: $BACKUP_FILE${NC}"
            
            # Verificar que el backup no está vacío
            if [ -s "$BACKUP_FILE" ]; then
                log "${GREEN}✅ Backup verificado ($(du -h "$BACKUP_FILE" | cut -f1))${NC}"
            else
                log "${YELLOW}⚠️  Backup está vacío${NC}"
            fi
        else
            log "${RED}❌ Error al crear backup${NC}"
            if ! confirm "¿Continuar sin backup?"; then
                exit 1
            fi
        fi
    fi
}

# Función para mostrar información antes de desinstalar
show_info() {
    log "${BLUE}📊 Información actual del deployment:${NC}"
    
    echo -e "\n${YELLOW}Pods:${NC}"
    kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" 2>/dev/null || echo "No pods encontrados"
    
    echo -e "\n${YELLOW}Services:${NC}"
    kubectl get svc -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" 2>/dev/null || echo "No services encontrados"
    
    echo -e "\n${YELLOW}PVCs:${NC}"
    kubectl get pvc -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" 2>/dev/null || echo "No PVCs encontrados"
    
    echo -e "\n${YELLOW}Ingress:${NC}"
    kubectl get ingress -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" 2>/dev/null || echo "No ingress encontrados"
    
    echo -e "\n${YELLOW}Secrets:${NC}"
    kubectl get secrets -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" 2>/dev/null || echo "No secrets encontrados"
}

# Función para desinstalar el release
uninstall_release() {
    log "${BLUE}🚀 Desinstalando release de Helm...${NC}"
    
    if helm uninstall "$RELEASE" --namespace "$NAMESPACE"; then
        log "${GREEN}✅ Release desinstalado exitosamente${NC}"
        
        # Esperar a que los pods se terminen
        log "${BLUE}⏳ Esperando a que los pods se terminen...${NC}"
        kubectl wait --for=delete pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" --timeout=120s 2>/dev/null || true
        
        return 0
    else
        log "${RED}❌ Error al desinstalar release${NC}"
        
        if confirm "¿Intentar desinstalación forzada?"; then
            log "${YELLOW}🔨 Intentando desinstalación forzada...${NC}"
            helm uninstall "$RELEASE" --namespace "$NAMESPACE" --no-hooks || true
            kubectl delete all -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" --force --grace-period=0 || true
            log "${GREEN}✅ Desinstalación forzada completada${NC}"
        else
            return 1
        fi
    fi
}

# Función para limpiar PVCs
cleanup_pvcs() {
    log "${BLUE}💾 Verificando PVCs...${NC}"
    
    PVCS=$(kubectl get pvc -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" --no-headers 2>/dev/null | awk '{print $1}')
    
    if [ -z "$PVCS" ]; then
        log "${GREEN}✅ No hay PVCs para limpiar${NC}"
        return 0
    fi
    
    echo -e "\n${YELLOW}PVCs encontrados:${NC}"
    kubectl get pvc -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE"
    
    echo -e "\n${RED}⚠️  ADVERTENCIA: Eliminar PVCs eliminará TODOS los datos de la base de datos${NC}"
    
    if confirm "¿Eliminar PVCs (esto eliminará TODOS los datos)?"; then
        log "${BLUE}🗑️ Eliminando PVCs...${NC}"
        
        for pvc in $PVCS; do
            log "${BLUE}Eliminando PVC: $pvc${NC}"
            if kubectl delete pvc -n "$NAMESPACE" "$pvc" --timeout=60s; then
                log "${GREEN}✅ PVC $pvc eliminado${NC}"
            else
                log "${YELLOW}⚠️  Forzando eliminación de PVC $pvc${NC}"
                kubectl patch pvc -n "$NAMESPACE" "$pvc" -p '{"metadata":{"finalizers":null}}' || true
            fi
        done
        
        log "${GREEN}✅ PVCs eliminados${NC}"
    else
        log "${BLUE}ℹ️  PVCs mantenidos para futura reinstalación${NC}"
    fi
}

# Función para limpiar recursos adicionales
cleanup_additional_resources() {
    log "${BLUE}🧹 Limpiando recursos adicionales...${NC}"
    
    # Limpiar secrets
    SECRETS=$(kubectl get secrets -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" --no-headers 2>/dev/null | awk '{print $1}')
    if [ -n "$SECRETS" ]; then
        log "${BLUE}🔐 Eliminando secrets...${NC}"
        kubectl delete secrets -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" || true
        log "${GREEN}✅ Secrets eliminados${NC}"
    fi
    
    # Limpiar configmaps
    CONFIGMAPS=$(kubectl get configmaps -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" --no-headers 2>/dev/null | awk '{print $1}')
    if [ -n "$CONFIGMAPS" ]; then
        log "${BLUE}📋 Eliminando configmaps...${NC}"
        kubectl delete configmaps -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" || true
        log "${GREEN}✅ ConfigMaps eliminados${NC}"
    fi
    
    # Limpiar service accounts
    SERVICE_ACCOUNTS=$(kubectl get serviceaccounts -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" --no-headers 2>/dev/null | awk '{print $1}')
    if [ -n "$SERVICE_ACCOUNTS" ]; then
        log "${BLUE}👤 Eliminando service accounts...${NC}"
        kubectl delete serviceaccounts -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" || true
        log "${GREEN}✅ Service accounts eliminados${NC}"
    fi
    
    # Limpiar role bindings
    ROLE_BINDINGS=$(kubectl get rolebindings -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" --no-headers 2>/dev/null | awk '{print $1}')
    if [ -n "$ROLE_BINDINGS" ]; then
        log "${BLUE}🔗 Eliminando role bindings...${NC}"
        kubectl delete rolebindings -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" || true
        log "${GREEN}✅ Role bindings eliminados${NC}"
    fi
}

# Función para limpiar namespace
cleanup_namespace() {
    # Verificar si el namespace tiene otros recursos
    OTHER_RESOURCES=$(kubectl get all -n "$NAMESPACE" --no-headers 2>/dev/null | wc -l)
    
    if [ "$OTHER_RESOURCES" -eq 0 ]; then
        if confirm "¿Eliminar el namespace '$NAMESPACE' (está vacío)?"; then
            log "${BLUE}🗂️ Eliminando namespace...${NC}"
            if kubectl delete namespace "$NAMESPACE" --timeout=120s; then
                log "${GREEN}✅ Namespace eliminado${NC}"
            else
                log "${YELLOW}⚠️  Forzando eliminación del namespace${NC}"
                kubectl patch namespace "$NAMESPACE" -p '{"metadata":{"finalizers":null}}' --type=merge || true
            fi
        fi
    else
        log "${BLUE}ℹ️  Namespace '$NAMESPACE' contiene otros recursos, no se eliminará${NC}"
        kubectl get all -n "$NAMESPACE" --no-headers | head -5
    fi
}

# Función para verificar limpieza
verify_cleanup() {
    log "${BLUE}🔍 Verificando limpieza...${NC}"
    
    # Verificar releases
    REMAINING_RELEASES=$(helm list -n "$NAMESPACE" | grep "$RELEASE" | wc -l)
    if [ "$REMAINING_RELEASES" -eq 0 ]; then
        log "${GREEN}✅ No quedan releases de Helm${NC}"
    else
        log "${YELLOW}⚠️  Aún quedan releases de Helm${NC}"
    fi
    
    # Verificar recursos
    REMAINING_RESOURCES=$(kubectl get all -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" --no-headers 2>/dev/null | wc -l)
    if [ "$REMAINING_RESOURCES" -eq 0 ]; then
        log "${GREEN}✅ No quedan recursos de Kubernetes${NC}"
    else
        log "${YELLOW}⚠️  Aún quedan $REMAINING_RESOURCES recursos${NC}"
        kubectl get all -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" 2>/dev/null || true
    fi
    
    # Verificar PVs huérfanos
    ORPHAN_PVS=$(kubectl get pv | grep "$NAMESPACE" | grep Available | wc -l)
    if [ "$ORPHAN_PVS" -gt 0 ]; then
        log "${YELLOW}⚠️  Encontrados $ORPHAN_PVS PVs huérfanos${NC}"
        if confirm "¿Eliminar PVs huérfanos?"; then
            kubectl get pv | grep "$NAMESPACE" | grep Available | awk '{print $1}' | xargs kubectl delete pv || true
            log "${GREEN}✅ PVs huérfanos eliminados${NC}"
        fi
    fi
}

# Función principal
main() {
    log "${BLUE}Iniciando proceso de desinstalación...${NC}"
    
    # Verificar dependencias
    check_dependencies
    
    # Mostrar información actual
    show_info
    
    echo -e "\n${RED}⚠️  ADVERTENCIA: Esta acción eliminará Aurora Gov del cluster${NC}"
    if ! confirm "¿Continuar con la desinstalación?"; then
        log "${BLUE}Desinstalación cancelada por el usuario${NC}"
        exit 0
    fi
    
    # Verificar release
    if check_release; then
        # Crear backup si se solicita
        create_backup
        
        # Desinstalar release
        uninstall_release
    fi
    
    # Limpiar PVCs
    cleanup_pvcs
    
    # Limpiar recursos adicionales
    cleanup_additional_resources
    
    # Limpiar namespace si está vacío
    cleanup_namespace
    
    # Verificar limpieza
    verify_cleanup
    
    log "${GREEN}🎉 Desinstalación completada exitosamente${NC}"
    
    # Mostrar información final
    echo -e "\n${BLUE}📋 Resumen:${NC}"
    echo "- Release: $RELEASE"
    echo "- Namespace: $NAMESPACE"
    if [ "$BACKUP" = "true" ] && [ -f "aurora-gov-backup-"*.sql ]; then
        echo "- Backup: $(ls aurora-gov-backup-*.sql 2>/dev/null | tail -1)"
    fi
    
    echo -e "\n${BLUE}💡 Para reinstalar:${NC}"
    echo "helm install $RELEASE ./helm/aurora-gov --namespace $NAMESPACE --create-namespace"
}

# Ejecutar función principal
main "$@"