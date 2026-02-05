#!/bin/bash

# Script para monitorear la instalación de Aurora Gov en tiempo real
# Uso: ./monitor-installation.sh [namespace] [release-name]

NAMESPACE="${1:-aurora-gov}"
RELEASE="${2:-aurora-gov}"
TIMEOUT=600  # 10 minutos

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🔍 Monitoreando instalación de Aurora Gov${NC}"
echo "Namespace: $NAMESPACE"
echo "Release: $RELEASE"
echo "Timeout: ${TIMEOUT}s"
echo "=================================="

# Función para mostrar timestamp
timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Función para log con timestamp
log() {
    echo -e "[$(timestamp)] $1"
}

# Función para verificar si un pod está listo
is_pod_ready() {
    local pod=$1
    local ready=$(kubectl get pod "$pod" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
    [ "$ready" = "True" ]
}

# Función para obtener el estado de un pod
get_pod_status() {
    local pod=$1
    kubectl get pod "$pod" -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null
}

# Función para mostrar progreso
show_progress() {
    local current=$1
    local total=$2
    local percent=$((current * 100 / total))
    local bar_length=20
    local filled_length=$((percent * bar_length / 100))
    
    printf "\rProgreso: ["
    for ((i=0; i<filled_length; i++)); do printf "█"; done
    for ((i=filled_length; i<bar_length; i++)); do printf "░"; done
    printf "] %d%% (%d/%d)" "$percent" "$current" "$total"
}

log "${BLUE}Iniciando monitoreo...${NC}"

# Verificar que el namespace existe
if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
    log "${RED}❌ Namespace '$NAMESPACE' no existe${NC}"
    exit 1
fi

# Verificar que el release existe
if ! helm status "$RELEASE" -n "$NAMESPACE" &>/dev/null; then
    log "${RED}❌ Release '$RELEASE' no encontrado en namespace '$NAMESPACE'${NC}"
    exit 1
fi

START_TIME=$(date +%s)

log "${GREEN}✅ Iniciando monitoreo de recursos...${NC}"

# Loop principal de monitoreo
while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    if [ $ELAPSED -gt $TIMEOUT ]; then
        log "${RED}❌ Timeout alcanzado (${TIMEOUT}s)${NC}"
        break
    fi
    
    clear
    echo -e "${BLUE}🔍 Aurora Gov - Monitor de Instalación${NC}"
    echo "Namespace: $NAMESPACE | Release: $RELEASE | Tiempo: ${ELAPSED}s/${TIMEOUT}s"
    echo "========================================================================"
    
    # Estado del release
    echo -e "\n${YELLOW}📦 Estado del Release:${NC}"
    RELEASE_STATUS=$(helm status "$RELEASE" -n "$NAMESPACE" -o json 2>/dev/null | jq -r '.info.status' 2>/dev/null || echo "unknown")
    case $RELEASE_STATUS in
        "deployed")
            echo -e "   ${GREEN}✅ Deployed${NC}"
            ;;
        "pending-install"|"pending-upgrade")
            echo -e "   ${YELLOW}⏳ $RELEASE_STATUS${NC}"
            ;;
        "failed")
            echo -e "   ${RED}❌ Failed${NC}"
            ;;
        *)
            echo -e "   ${YELLOW}❓ $RELEASE_STATUS${NC}"
            ;;
    esac
    
    # Estado de los pods
    echo -e "\n${YELLOW}🚀 Estado de Pods:${NC}"
    PODS=$(kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" --no-headers 2>/dev/null)
    
    if [ -z "$PODS" ]; then
        echo "   No hay pods encontrados"
    else
        TOTAL_PODS=$(echo "$PODS" | wc -l)
        READY_PODS=0
        
        while IFS= read -r line; do
            POD_NAME=$(echo "$line" | awk '{print $1}')
            POD_STATUS=$(echo "$line" | awk '{print $3}')
            POD_READY=$(echo "$line" | awk '{print $2}')
            
            case $POD_STATUS in
                "Running")
                    if [[ "$POD_READY" == *"/"* ]]; then
                        READY_COUNT=$(echo "$POD_READY" | cut -d'/' -f1)
                        TOTAL_COUNT=$(echo "$POD_READY" | cut -d'/' -f2)
                        if [ "$READY_COUNT" = "$TOTAL_COUNT" ]; then
                            echo -e "   ${GREEN}✅ $POD_NAME ($POD_STATUS)${NC}"
                            ((READY_PODS++))
                        else
                            echo -e "   ${YELLOW}⏳ $POD_NAME ($POD_STATUS - $POD_READY)${NC}"
                        fi
                    else
                        echo -e "   ${GREEN}✅ $POD_NAME ($POD_STATUS)${NC}"
                        ((READY_PODS++))
                    fi
                    ;;
                "Pending")
                    echo -e "   ${YELLOW}⏳ $POD_NAME ($POD_STATUS)${NC}"
                    ;;
                "ContainerCreating"|"PodInitializing")
                    echo -e "   ${BLUE}🔄 $POD_NAME ($POD_STATUS)${NC}"
                    ;;
                "CrashLoopBackOff"|"Error"|"Failed")
                    echo -e "   ${RED}❌ $POD_NAME ($POD_STATUS)${NC}"
                    ;;
                *)
                    echo -e "   ${YELLOW}❓ $POD_NAME ($POD_STATUS)${NC}"
                    ;;
            esac
        done <<< "$PODS"
        
        echo -e "\n   "
        show_progress $READY_PODS $TOTAL_PODS
        echo
    fi
    
    # Estado de los services
    echo -e "\n${YELLOW}🌐 Estado de Services:${NC}"
    SERVICES=$(kubectl get svc -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" --no-headers 2>/dev/null)
    
    if [ -z "$SERVICES" ]; then
        echo "   No hay services encontrados"
    else
        while IFS= read -r line; do
            SVC_NAME=$(echo "$line" | awk '{print $1}')
            SVC_TYPE=$(echo "$line" | awk '{print $2}')
            SVC_CLUSTER_IP=$(echo "$line" | awk '{print $3}')
            SVC_EXTERNAL_IP=$(echo "$line" | awk '{print $4}')
            
            if [ "$SVC_CLUSTER_IP" != "<none>" ]; then
                echo -e "   ${GREEN}✅ $SVC_NAME ($SVC_TYPE) - $SVC_CLUSTER_IP${NC}"
            else
                echo -e "   ${YELLOW}⏳ $SVC_NAME ($SVC_TYPE)${NC}"
            fi
        done <<< "$SERVICES"
    fi
    
    # Estado del ingress
    echo -e "\n${YELLOW}🔗 Estado de Ingress:${NC}"
    INGRESSES=$(kubectl get ingress -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" --no-headers 2>/dev/null)
    
    if [ -z "$INGRESSES" ]; then
        echo "   No hay ingress encontrados"
    else
        while IFS= read -r line; do
            ING_NAME=$(echo "$line" | awk '{print $1}')
            ING_CLASS=$(echo "$line" | awk '{print $2}')
            ING_HOSTS=$(echo "$line" | awk '{print $3}')
            ING_ADDRESS=$(echo "$line" | awk '{print $4}')
            
            if [ "$ING_ADDRESS" != "<none>" ] && [ -n "$ING_ADDRESS" ]; then
                echo -e "   ${GREEN}✅ $ING_NAME - $ING_HOSTS ($ING_ADDRESS)${NC}"
            else
                echo -e "   ${YELLOW}⏳ $ING_NAME - $ING_HOSTS (esperando IP)${NC}"
            fi
        done <<< "$INGRESSES"
    fi
    
    # PVCs
    echo -e "\n${YELLOW}💾 Estado de PVCs:${NC}"
    PVCS=$(kubectl get pvc -n "$NAMESPACE" -l "app.kubernetes.io/instance=$RELEASE" --no-headers 2>/dev/null)
    
    if [ -z "$PVCS" ]; then
        echo "   No hay PVCs encontrados"
    else
        while IFS= read -r line; do
            PVC_NAME=$(echo "$line" | awk '{print $1}')
            PVC_STATUS=$(echo "$line" | awk '{print $2}')
            PVC_VOLUME=$(echo "$line" | awk '{print $3}')
            PVC_CAPACITY=$(echo "$line" | awk '{print $4}')
            
            case $PVC_STATUS in
                "Bound")
                    echo -e "   ${GREEN}✅ $PVC_NAME ($PVC_STATUS) - $PVC_CAPACITY${NC}"
                    ;;
                "Pending")
                    echo -e "   ${YELLOW}⏳ $PVC_NAME ($PVC_STATUS)${NC}"
                    ;;
                *)
                    echo -e "   ${RED}❌ $PVC_NAME ($PVC_STATUS)${NC}"
                    ;;
            esac
        done <<< "$PVCS"
    fi
    
    # Eventos recientes
    echo -e "\n${YELLOW}📋 Eventos Recientes:${NC}"
    EVENTS=$(kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' --no-headers 2>/dev/null | tail -5)
    
    if [ -z "$EVENTS" ]; then
        echo "   No hay eventos recientes"
    else
        while IFS= read -r line; do
            EVENT_TIME=$(echo "$line" | awk '{print $1}')
            EVENT_TYPE=$(echo "$line" | awk '{print $2}')
            EVENT_REASON=$(echo "$line" | awk '{print $3}')
            EVENT_OBJECT=$(echo "$line" | awk '{print $4}')
            EVENT_MESSAGE=$(echo "$line" | cut -d' ' -f5-)
            
            case $EVENT_TYPE in
                "Normal")
                    echo -e "   ${GREEN}ℹ️  $EVENT_TIME - $EVENT_REASON: $EVENT_MESSAGE${NC}"
                    ;;
                "Warning")
                    echo -e "   ${YELLOW}⚠️  $EVENT_TIME - $EVENT_REASON: $EVENT_MESSAGE${NC}"
                    ;;
                *)
                    echo -e "   ${RED}❗ $EVENT_TIME - $EVENT_REASON: $EVENT_MESSAGE${NC}"
                    ;;
            esac
        done <<< "$EVENTS"
    fi
    
    # Verificar si la instalación está completa
    if [ "$RELEASE_STATUS" = "deployed" ] && [ "$READY_PODS" -eq "$TOTAL_PODS" ] && [ "$TOTAL_PODS" -gt 0 ]; then
        echo -e "\n${GREEN}🎉 ¡Instalación completada exitosamente!${NC}"
        echo -e "\n${BLUE}📋 Información de acceso:${NC}"
        
        # Mostrar información de acceso
        if [ -n "$INGRESSES" ]; then
            echo "   URL: https://$(echo "$INGRESSES" | awk '{print $3}' | head -1)"
        fi
        
        echo -e "\n${BLUE}🔧 Comandos útiles:${NC}"
        echo "   Ver logs: kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=aurora-gov -f"
        echo "   Port forward: kubectl port-forward -n $NAMESPACE svc/$RELEASE 8080:80"
        echo "   Estado: helm status $RELEASE -n $NAMESPACE"
        
        break
    fi
    
    # Verificar si hay errores críticos
    ERROR_PODS=$(echo "$PODS" | grep -E "(CrashLoopBackOff|Error|Failed)" | wc -l)
    if [ "$ERROR_PODS" -gt 0 ]; then
        echo -e "\n${RED}⚠️  Se detectaron $ERROR_PODS pod(s) con errores${NC}"
        echo -e "${YELLOW}💡 Ejecuta el siguiente comando para ver logs de error:${NC}"
        echo "   kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=aurora-gov --previous"
    fi
    
    sleep 5
done

log "${BLUE}Monitoreo finalizado${NC}"