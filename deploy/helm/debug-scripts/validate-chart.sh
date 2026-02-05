#!/bin/bash

# Script para validar el chart de Aurora Gov antes de la instalación
# Uso: ./validate-chart.sh [values-file]

set -e

CHART_PATH="./helm/aurora-gov"
VALUES_FILE="${1:-values.yaml}"
NAMESPACE="aurora-gov-test"

echo "🔍 Validando Aurora Gov Helm Chart..."
echo "Chart: $CHART_PATH"
echo "Values: $VALUES_FILE"
echo "Namespace: $NAMESPACE"
echo "=================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para mostrar resultados
show_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        return 1
    fi
}

# Función para mostrar warnings
show_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

echo "1. Verificando dependencias..."

# Verificar que helm esté instalado
if ! command -v helm &> /dev/null; then
    echo -e "${RED}❌ Helm no está instalado${NC}"
    exit 1
fi
show_result 0 "Helm está instalado ($(helm version --short))"

# Verificar que kubectl esté instalado
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl no está instalado${NC}"
    exit 1
fi
show_result 0 "kubectl está instalado ($(kubectl version --client --short))"

# Verificar conexión al cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ No se puede conectar al cluster de Kubernetes${NC}"
    exit 1
fi
show_result 0 "Conexión al cluster OK"

echo -e "\n2. Validando estructura del chart..."

# Verificar que el chart existe
if [ ! -d "$CHART_PATH" ]; then
    echo -e "${RED}❌ Chart no encontrado en $CHART_PATH${NC}"
    exit 1
fi
show_result 0 "Chart encontrado"

# Verificar Chart.yaml
if [ ! -f "$CHART_PATH/Chart.yaml" ]; then
    echo -e "${RED}❌ Chart.yaml no encontrado${NC}"
    exit 1
fi
show_result 0 "Chart.yaml existe"

# Verificar values.yaml
if [ ! -f "$CHART_PATH/values.yaml" ]; then
    echo -e "${RED}❌ values.yaml no encontrado${NC}"
    exit 1
fi
show_result 0 "values.yaml existe"

# Verificar templates directory
if [ ! -d "$CHART_PATH/templates" ]; then
    echo -e "${RED}❌ Directorio templates no encontrado${NC}"
    exit 1
fi
show_result 0 "Directorio templates existe"

echo -e "\n3. Ejecutando helm lint..."

# Lint del chart
if helm lint "$CHART_PATH" > /tmp/helm-lint.log 2>&1; then
    show_result 0 "Helm lint pasó sin errores"
else
    show_result 1 "Helm lint falló"
    echo "Errores de lint:"
    cat /tmp/helm-lint.log
    exit 1
fi

# Lint con valores específicos si se proporciona
if [ "$VALUES_FILE" != "values.yaml" ] && [ -f "$CHART_PATH/$VALUES_FILE" ]; then
    if helm lint "$CHART_PATH" -f "$CHART_PATH/$VALUES_FILE" > /tmp/helm-lint-values.log 2>&1; then
        show_result 0 "Helm lint con $VALUES_FILE pasó sin errores"
    else
        show_result 1 "Helm lint con $VALUES_FILE falló"
        echo "Errores de lint con valores:"
        cat /tmp/helm-lint-values.log
        exit 1
    fi
fi

echo -e "\n4. Validando templates..."

# Template rendering test
if helm template test-release "$CHART_PATH" > /tmp/helm-template.yaml 2>/tmp/helm-template.log; then
    show_result 0 "Templates se renderizan correctamente"
else
    show_result 1 "Error al renderizar templates"
    echo "Errores de template:"
    cat /tmp/helm-template.log
    exit 1
fi

# Validar YAML generado
if kubectl apply --dry-run=client -f /tmp/helm-template.yaml > /dev/null 2>/tmp/kubectl-validate.log; then
    show_result 0 "YAML generado es válido"
else
    show_result 1 "YAML generado contiene errores"
    echo "Errores de validación:"
    cat /tmp/kubectl-validate.log
    exit 1
fi

echo -e "\n5. Verificando recursos del cluster..."

# Verificar storage classes
STORAGE_CLASSES=$(kubectl get storageclass --no-headers 2>/dev/null | wc -l)
if [ "$STORAGE_CLASSES" -gt 0 ]; then
    show_result 0 "Storage classes disponibles ($STORAGE_CLASSES)"
    kubectl get storageclass --no-headers | head -3
else
    show_warning "No hay storage classes disponibles"
fi

# Verificar ingress controllers
INGRESS_CLASSES=$(kubectl get ingressclass --no-headers 2>/dev/null | wc -l)
if [ "$INGRESS_CLASSES" -gt 0 ]; then
    show_result 0 "Ingress classes disponibles ($INGRESS_CLASSES)"
    kubectl get ingressclass --no-headers | head -3
else
    show_warning "No hay ingress classes disponibles"
fi

# Verificar cert-manager
if kubectl get pods -n cert-manager &> /dev/null; then
    CERT_MANAGER_PODS=$(kubectl get pods -n cert-manager --no-headers | grep Running | wc -l)
    if [ "$CERT_MANAGER_PODS" -gt 0 ]; then
        show_result 0 "cert-manager está corriendo ($CERT_MANAGER_PODS pods)"
    else
        show_warning "cert-manager no está corriendo correctamente"
    fi
else
    show_warning "cert-manager no está instalado"
fi

echo -e "\n6. Simulando instalación (dry-run)..."

# Dry run de la instalación
if helm install test-release "$CHART_PATH" \
    --namespace "$NAMESPACE" \
    --create-namespace \
    --dry-run \
    --debug > /tmp/helm-install-dry.log 2>&1; then
    show_result 0 "Dry-run de instalación exitoso"
else
    show_result 1 "Dry-run de instalación falló"
    echo "Errores de dry-run:"
    tail -20 /tmp/helm-install-dry.log
    exit 1
fi

echo -e "\n7. Verificando configuraciones específicas..."

# Verificar que los secrets se generen correctamente
SECRET_KEY_BASE=$(helm template test-release "$CHART_PATH" --show-only templates/secret.yaml | grep secret-key-base | wc -l)
if [ "$SECRET_KEY_BASE" -gt 0 ]; then
    show_result 0 "Secret key base se genera correctamente"
else
    show_warning "Secret key base podría no generarse"
fi

# Verificar configuración de PostgreSQL
PG_CONFIG=$(helm template test-release "$CHART_PATH" --show-only templates/postgresql-statefulset.yaml | grep POSTGRES_PASSWORD | wc -l)
if [ "$PG_CONFIG" -gt 0 ]; then
    show_result 0 "Configuración de PostgreSQL es correcta"
else
    show_warning "Configuración de PostgreSQL podría tener problemas"
fi

# Verificar health checks
HEALTH_CHECKS=$(helm template test-release "$CHART_PATH" --show-only templates/deployment.yaml | grep -E "(livenessProbe|readinessProbe)" | wc -l)
if [ "$HEALTH_CHECKS" -gt 0 ]; then
    show_result 0 "Health checks configurados ($HEALTH_CHECKS)"
else
    show_warning "Health checks no configurados"
fi

echo -e "\n8. Generando reporte de validación..."

# Crear reporte
REPORT_FILE="/tmp/aurora-gov-validation-report.txt"
cat > "$REPORT_FILE" << EOF
Aurora Gov Helm Chart Validation Report
=======================================
Fecha: $(date)
Chart: $CHART_PATH
Values: $VALUES_FILE
Cluster: $(kubectl config current-context)

Versiones:
- Helm: $(helm version --short)
- kubectl: $(kubectl version --client --short)
- Kubernetes: $(kubectl version --short 2>/dev/null | grep Server || echo "No disponible")

Recursos del Cluster:
- Nodos: $(kubectl get nodes --no-headers | wc -l)
- Storage Classes: $STORAGE_CLASSES
- Ingress Classes: $INGRESS_CLASSES
- Namespaces: $(kubectl get namespaces --no-headers | wc -l)

Validaciones:
✅ Estructura del chart
✅ Helm lint
✅ Template rendering
✅ YAML validation
✅ Dry-run installation

Archivos generados:
- Templates: /tmp/helm-template.yaml
- Lint log: /tmp/helm-lint.log
- Dry-run log: /tmp/helm-install-dry.log

EOF

echo -e "${GREEN}✅ Validación completada exitosamente!${NC}"
echo "Reporte guardado en: $REPORT_FILE"

echo -e "\n📋 Próximos pasos:"
echo "1. Revisar el reporte de validación"
echo "2. Ejecutar instalación real:"
echo "   helm install aurora-gov $CHART_PATH --namespace $NAMESPACE --create-namespace"
echo "3. Monitorear la instalación:"
echo "   kubectl get pods -n $NAMESPACE -w"

# Limpiar archivos temporales opcionales
read -p "¿Limpiar archivos temporales? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -f /tmp/helm-*.log /tmp/helm-*.yaml /tmp/kubectl-*.log
    echo "Archivos temporales limpiados"
fi

exit 0