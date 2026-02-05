#!/bin/bash

# Script de troubleshooting para Aurora Gov
# Uso: ./troubleshoot.sh [namespace] [release-name]

NAMESPACE="${1:-aurora-gov}"
RELEASE="${2:-aurora-gov}"
OUTPUT_DIR="/tmp/aurora-gov-debug-$(date +%Y%m%d-%H%M%S)"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔧 Aurora Gov Troubleshooting Tool${NC}"
echo "Namespace: $NAMESPACE"
echo "Release: $RELEASE"
echo "Output: $OUTPUT_DIR"
echo "=================================="

# Crear directorio de output
mkdir -p "$OUTPUT_DIR"

# Función para log con timestamp
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$OUTPUT_DIR/troubleshoot.log"
}

# Función para ejecutar comando y guardar output
run_cmd() {
    local cmd="$1"
    local output_file="$2"
    local description="$3"
    
    log "${BLUE}Ejecutando: $description${NC}"
    echo "# $description" > "$OUTPUT_DIR/$output_file"
    echo "# Comando: $cmd" >> "$OUTPUT_DIR/$output_file"
    echo "# Fecha: $(date)" >> "$OUTPUT_DIR/$output_file"
    echo "" >> "$OUTPUT_DIR/$output_file"
    
    if eval "$cmd" >> "$OUTPUT_DIR/$output_file" 2>&1; then
        log "${GREEN}✅ $description - OK${NC}"
    else
        log "${RED}❌ $description - ERROR${NC}"
    fi
}

log "${BLUE}Iniciando recolección de información de debug...${NC}"

# 1. Información general del cluster
log "${YELLOW}📊 Recolectando información del cluster...${NC}"
run_cmd "kubectl cluster-info" "01-cluster-info.txt" "Información del cluster"
run_cmd "kubectl version" "02-versions.txt" "Versiones de Kubernetes"
run_cmd "kubectl get nodes -o wide" "03-nodes.txt" "Información de nodos"
run_cmd "kubectl get namespaces" "04-namespaces.txt" "Namespaces disponibles"

# 2. Información del release
log "${YELLOW}📦 Recolectando información del release...${NC}"
run_cmd "helm version" "05-helm-version.txt" "Versión de Helm"
run_cmd "helm list -n $NAMESPACE" "06-helm-releases.txt" "Releases en el namespace"
run_cmd "helm status $RELEASE -n $NAMESPACE" "07-release-status.txt" "Estado del release"
run_cmd "helm get values $RELEASE -n $NAMESPACE" "08-release-values.yaml" "Valores del release"
run_cmd "helm get manifest $RELEASE -n $NAMESPACE" "09-release-manifest.yaml" "Manifests del release"
run_cmd "helm history $RELEASE -n $NAMESPACE" "10-release-history.txt" "Historial del release"

# 3. Recursos de Kubernetes
log "${YELLOW}🚀 Recolectando información de recursos...${NC}"
run_cmd "kubectl get all -n $NAMESPACE -o wide" "11-all-resources.txt" "Todos los recursos"
run_cmd "kubectl get pods -n $NAMESPACE -o wide" "12-pods.txt" "Información de pods"
run_cmd "kubectl get svc -n $NAMESPACE -o wide" "13-services.txt" "Información de services"
run_cmd "kubectl get ingress -n $NAMESPACE -o wide" "14-ingress.txt" "Información de ingress"
run_cmd "kubectl get pvc -n $NAMESPACE -o wide" "15-pvc.txt" "Información de PVCs"
run_cmd "kubectl get pv" "16-pv.txt" "Información de PVs"
run_cmd "kubectl get secrets -n $NAMESPACE" "17-secrets.txt" "Información de secrets"
run_cmd "kubectl get configmaps -n $NAMESPACE" "18-configmaps.txt" "Información de configmaps"

# 4. Eventos
log "${YELLOW}📋 Recolectando eventos...${NC}"
run_cmd "kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'" "19-events.txt" "Eventos del namespace"
run_cmd "kubectl get events --all-namespaces --sort-by='.lastTimestamp' | grep -E '(Warning|Error)' | tail -50" "20-cluster-errors.txt" "Errores del cluster"

# 5. Descripción detallada de recursos
log "${YELLOW}🔍 Recolectando descripciones detalladas...${NC}"

# Pods
PODS=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" --no-headers 2>/dev/null | awk '{print $1}')
if [ -n "$PODS" ]; then
    mkdir -p "$OUTPUT_DIR/pod-descriptions"
    while IFS= read -r pod; do
        run_cmd "kubectl describe pod $pod -n $NAMESPACE" "pod-descriptions/$pod.txt" "Descripción del pod $pod"
    done <<< "$PODS"
fi

# Services
SERVICES=$(kubectl get svc -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" --no-headers 2>/dev/null | awk '{print $1}')
if [ -n "$SERVICES" ]; then
    mkdir -p "$OUTPUT_DIR/service-descriptions"
    while IFS= read -r svc; do
        run_cmd "kubectl describe svc $svc -n $NAMESPACE" "service-descriptions/$svc.txt" "Descripción del service $svc"
    done <<< "$SERVICES"
fi

# Ingress
INGRESSES=$(kubectl get ingress -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" --no-headers 2>/dev/null | awk '{print $1}')
if [ -n "$INGRESSES" ]; then
    mkdir -p "$OUTPUT_DIR/ingress-descriptions"
    while IFS= read -r ing; do
        run_cmd "kubectl describe ingress $ing -n $NAMESPACE" "ingress-descriptions/$ing.txt" "Descripción del ingress $ing"
    done <<< "$INGRESSES"
fi

# 6. Logs de pods
log "${YELLOW}📝 Recolectando logs...${NC}"
if [ -n "$PODS" ]; then
    mkdir -p "$OUTPUT_DIR/pod-logs"
    while IFS= read -r pod; do
        # Logs actuales
        run_cmd "kubectl logs $pod -n $NAMESPACE --tail=1000" "pod-logs/$pod-current.log" "Logs actuales del pod $pod"
        
        # Logs anteriores (si existen)
        if kubectl logs "$pod" -n "$NAMESPACE" --previous &>/dev/null; then
            run_cmd "kubectl logs $pod -n $NAMESPACE --previous --tail=1000" "pod-logs/$pod-previous.log" "Logs anteriores del pod $pod"
        fi
        
        # Logs de todos los containers si es multi-container
        CONTAINERS=$(kubectl get pod "$pod" -n "$NAMESPACE" -o jsonpath='{.spec.containers[*].name}' 2>/dev/null)
        if [ "$(echo "$CONTAINERS" | wc -w)" -gt 1 ]; then
            for container in $CONTAINERS; do
                run_cmd "kubectl logs $pod -c $container -n $NAMESPACE --tail=500" "pod-logs/$pod-$container.log" "Logs del container $container en pod $pod"
            done
        fi
    done <<< "$PODS"
fi

# 7. Información de storage
log "${YELLOW}💾 Recolectando información de storage...${NC}"
run_cmd "kubectl get storageclass" "21-storage-classes.txt" "Storage classes disponibles"

PVCS=$(kubectl get pvc -n "$NAMESPACE" --no-headers 2>/dev/null | awk '{print $1}')
if [ -n "$PVCS" ]; then
    mkdir -p "$OUTPUT_DIR/pvc-descriptions"
    while IFS= read -r pvc; do
        run_cmd "kubectl describe pvc $pvc -n $NAMESPACE" "pvc-descriptions/$pvc.txt" "Descripción del PVC $pvc"
    done <<< "$PVCS"
fi

# 8. Información de red
log "${YELLOW}🌐 Recolectando información de red...${NC}"
run_cmd "kubectl get networkpolicy -n $NAMESPACE" "22-network-policies.txt" "Network policies"
run_cmd "kubectl get ingressclass" "23-ingress-classes.txt" "Ingress classes disponibles"

# 9. Información de seguridad
log "${YELLOW}🔒 Recolectando información de seguridad...${NC}"
run_cmd "kubectl get serviceaccount -n $NAMESPACE" "24-service-accounts.txt" "Service accounts"
run_cmd "kubectl get rolebinding -n $NAMESPACE" "25-role-bindings.txt" "Role bindings"
run_cmd "kubectl get role -n $NAMESPACE" "26-roles.txt" "Roles"

# 10. Recursos del sistema
log "${YELLOW}📊 Recolectando métricas de recursos...${NC}"
if kubectl top nodes &>/dev/null; then
    run_cmd "kubectl top nodes" "27-node-metrics.txt" "Métricas de nodos"
    run_cmd "kubectl top pods -n $NAMESPACE" "28-pod-metrics.txt" "Métricas de pods"
else
    log "${YELLOW}⚠️  Metrics server no disponible${NC}"
fi

# 11. Información específica de Aurora Gov
log "${YELLOW}🌅 Recolectando información específica de Aurora Gov...${NC}"

# Verificar conectividad a la base de datos
if [ -n "$PODS" ]; then
    APP_POD=$(echo "$PODS" | grep -v postgresql | head -1)
    if [ -n "$APP_POD" ]; then
        run_cmd "kubectl exec $APP_POD -n $NAMESPACE -- env | grep -E '(DATABASE|POSTGRES)'" "29-db-env-vars.txt" "Variables de entorno de BD"
    fi
fi

# Verificar secrets específicos
run_cmd "kubectl get secret -n $NAMESPACE -o yaml | grep -A 5 -B 5 'secret-key-base\\|postgres-password'" "30-secret-keys.txt" "Keys de secrets importantes"

# 12. Tests de conectividad
log "${YELLOW}🔌 Ejecutando tests de conectividad...${NC}"

# Test de conectividad interna
if [ -n "$SERVICES" ]; then
    SVC_NAME=$(echo "$SERVICES" | head -1)
    run_cmd "kubectl run connectivity-test --image=busybox:1.35 --rm -i --restart=Never --namespace=$NAMESPACE -- nslookup $SVC_NAME.$NAMESPACE.svc.cluster.local" "31-connectivity-test.txt" "Test de conectividad DNS"
fi

# 13. Generar resumen
log "${YELLOW}📋 Generando resumen...${NC}"

cat > "$OUTPUT_DIR/RESUMEN.md" << EOF
# Aurora Gov - Resumen de Troubleshooting

**Fecha:** $(date)
**Namespace:** $NAMESPACE
**Release:** $RELEASE
**Cluster:** $(kubectl config current-context)

## Estado General

### Release
$(helm status "$RELEASE" -n "$NAMESPACE" 2>/dev/null | head -10 || echo "Release no encontrado")

### Pods
\`\`\`
$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" 2>/dev/null || echo "No pods encontrados")
\`\`\`

### Services
\`\`\`
$(kubectl get svc -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" 2>/dev/null || echo "No services encontrados")
\`\`\`

### Eventos Recientes (Últimos 10)
\`\`\`
$(kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' --no-headers 2>/dev/null | tail -10 || echo "No eventos encontrados")
\`\`\`

## Archivos Generados

- **01-04:** Información del cluster
- **05-10:** Información del release Helm
- **11-18:** Recursos de Kubernetes
- **19-20:** Eventos y errores
- **21-28:** Storage, red y métricas
- **29-31:** Información específica de Aurora Gov
- **pod-descriptions/:** Descripciones detalladas de pods
- **pod-logs/:** Logs de todos los pods
- **service-descriptions/:** Descripciones de services
- **ingress-descriptions/:** Descripciones de ingress
- **pvc-descriptions/:** Descripciones de PVCs

## Próximos Pasos

1. Revisar los logs en \`pod-logs/\`
2. Verificar eventos en \`19-events.txt\`
3. Comprobar configuración en \`08-release-values.yaml\`
4. Analizar descripciones de pods con problemas

## Comandos Útiles

\`\`\`bash
# Ver logs en tiempo real
kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=aurora-gov -f

# Acceder a un pod
kubectl exec -it -n $NAMESPACE <pod-name> -- /bin/sh

# Port forward para acceso local
kubectl port-forward -n $NAMESPACE svc/$RELEASE 8080:80

# Reinstalar si es necesario
helm uninstall $RELEASE -n $NAMESPACE
helm install $RELEASE ./helm/aurora-gov -n $NAMESPACE
\`\`\`
EOF

# 14. Comprimir resultados
log "${YELLOW}📦 Comprimiendo resultados...${NC}"
cd "$(dirname "$OUTPUT_DIR")"
tar -czf "$(basename "$OUTPUT_DIR").tar.gz" "$(basename "$OUTPUT_DIR")"

log "${GREEN}✅ Troubleshooting completado!${NC}"
log "${BLUE}📁 Resultados guardados en: $OUTPUT_DIR${NC}"
log "${BLUE}📦 Archivo comprimido: $OUTPUT_DIR.tar.gz${NC}"

echo -e "\n${YELLOW}📋 Resumen de archivos generados:${NC}"
find "$OUTPUT_DIR" -type f | sort | while read -r file; do
    size=$(du -h "$file" | cut -f1)
    echo "  $size - $(basename "$file")"
done

echo -e "\n${BLUE}💡 Para analizar los resultados:${NC}"
echo "1. Revisar RESUMEN.md para una vista general"
echo "2. Verificar logs en pod-logs/ para errores específicos"
echo "3. Comprobar eventos en 19-events.txt"
echo "4. Analizar configuración en 08-release-values.yaml"

echo -e "\n${BLUE}🆘 Si necesitas ayuda adicional:${NC}"
echo "- Envía el archivo $OUTPUT_DIR.tar.gz al equipo de soporte"
echo "- Email: p.delgado@aurora.ong"
echo "- Incluye descripción del problema y pasos para reproducirlo"