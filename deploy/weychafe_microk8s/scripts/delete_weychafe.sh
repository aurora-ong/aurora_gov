#!/usr/bin/env bash
# ==============================================================================
# AuroraGov - Script de Desinstalación Completa (MicroK8s / Kubernetes)
# ==============================================================================
set -euo pipefail

# Colores para la salida en consola
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

NAMESPACE=""
RELEASE="aurora-gov"
FORCE=false
KEEP_DATA=false

show_help() {
  cat << EOF
Uso: $0 [OPCIONES] [NAMESPACE]

Script para desinstalar completamente una instancia de AuroraGov en MicroK8s,
incluyendo release de Helm, Namespace de Kubernetes, PersistentVolumes y datos en disco.

ARGUMENTOS:
  NAMESPACE                     Nombre del namespace a eliminar (o usar -n / --namespace).

OPCIONES:
  -n, --namespace NAMESPACE     Namespace de Kubernetes de la instancia a desinstalar.
  -r, --release NOMBRE_RELEASE  Nombre del release de Helm (por defecto: aurora-gov).
  -y, --yes, --force            Omite la confirmación interactiva.
      --keep-data               Desinstala pods y namespace pero conserva los datos en disco
                                (/opt/aurora-gov/[NAMESPACE]).
  -h, --help                    Muestra esta ayuda.

EJEMPLOS:
  # Desinstalar instancia interactiva
  $0 aurora-gov-demo

  # Desinstalar sin confirmación (para scripts o CI/CD)
  $0 -n aurora-gov-demo -y

  # Desinstalar con nombre de release personalizado
  $0 -n instancia-alpha -r instancia-alpha -y
EOF
}

# Procesar argumentos
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    -r|--release)
      RELEASE="$2"
      shift 2
      ;;
    -y|--yes|--force)
      FORCE=true
      shift
      ;;
    --keep-data)
      KEEP_DATA=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      if [[ -z "$NAMESPACE" ]]; then
        NAMESPACE="$1"
        shift
      else
        echo -e "${RED}Error: Opción desconocida: $1${NC}" >&2
        show_help
        exit 1
      fi
      ;;
  esac
done

if [[ -z "$NAMESPACE" ]]; then
  echo -e "${RED}Error: Debes especificar el Namespace de la instancia a desinstalar.${NC}" >&2
  show_help
  exit 1
fi

# Detección de binarios de Helm y Kubectl
HELM_CMD=""
if command -v microk8s >/dev/null 2>&1 && microk8s helm version >/dev/null 2>&1; then
  HELM_CMD="microk8s helm"
elif command -v helm >/dev/null 2>&1; then
  HELM_CMD="helm"
elif command -v microk8s.helm >/dev/null 2>&1; then
  HELM_CMD="microk8s.helm"
fi

KUBECTL_CMD=""
if command -v microk8s >/dev/null 2>&1 && microk8s kubectl version --client >/dev/null 2>&1; then
  KUBECTL_CMD="microk8s kubectl"
elif command -v kubectl >/dev/null 2>&1; then
  KUBECTL_CMD="kubectl"
elif command -v microk8s.kubectl >/dev/null 2>&1; then
  KUBECTL_CMD="microk8s.kubectl"
fi

if [[ -z "$HELM_CMD" || -z "$KUBECTL_CMD" ]]; then
  echo -e "${RED}Error: Se requieren 'helm' y 'kubectl' (o 'microk8s helm' / 'microk8s kubectl').${NC}" >&2
  exit 1
fi

# Confirmación previa
if [[ "$FORCE" == "false" ]]; then
  echo -e "${BLUE}======================================================${NC}"
  echo -e "${YELLOW}⚠️  ADVERTENCIA: Se eliminará completamente la instancia${NC}"
  echo -e "${BLUE}======================================================${NC}"
  echo -e "  Namespace:      ${CYAN}${NAMESPACE}${NC}"
  echo -e "  Release Helm:   ${CYAN}${RELEASE}${NC}"
  if [[ "$KEEP_DATA" == "false" ]]; then
    echo -e "  Datos en disco: ${RED}/opt/aurora-gov/${NAMESPACE}${NC} (Postgres + Uploads)"
  else
    echo -e "  Datos en disco: ${GREEN}Se conservarán${NC} (--keep-data)"
  fi
  echo -e "${BLUE}======================================================${NC}"
  echo ""
  read -rp "¿Estás seguro de que deseas eliminar esta instancia? [s/N]: " CONFIRM
  if [[ "$CONFIRM" != "s" && "$CONFIRM" != "S" && "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo -e "${YELLOW}Operación cancelada.${NC}"
    exit 0
  fi
  echo ""
fi

echo -e "${BLUE}>>> Iniciando proceso de eliminación...${NC}"

# 1. Desinstalar release de Helm
echo -e "${CYAN}[1/4] Desinstalando release Helm '${RELEASE}' en namespace '${NAMESPACE}'...${NC}"
if $HELM_CMD status "$RELEASE" -n "$NAMESPACE" >/dev/null 2>&1; then
  $HELM_CMD uninstall "$RELEASE" -n "$NAMESPACE"
  echo -e "${GREEN}✓ Release de Helm desinstalado.${NC}"
else
  echo -e "${YELLOW}Aviso: El release '${RELEASE}' no existía en Helm.${NC}"
fi

# 2. Eliminar PersistentVolumes del clúster
echo -e "${CYAN}[2/4] Limpiando PersistentVolumes asociados al release...${NC}"
$KUBECTL_CMD delete pv "${NAMESPACE}-${RELEASE}-database-pv" "${NAMESPACE}-${RELEASE}-uploads-pv" --ignore-not-found 2>/dev/null || true
$KUBECTL_CMD delete pv "aurora-gov-database-pv" "aurora-gov-uploads-pv" --ignore-not-found 2>/dev/null || true
echo -e "${GREEN}✓ PersistentVolumes eliminados.${NC}"

# 3. Eliminar Namespace de Kubernetes
echo -e "${CYAN}[3/4] Eliminando namespace de Kubernetes '${NAMESPACE}'...${NC}"
if $KUBECTL_CMD get namespace "$NAMESPACE" >/dev/null 2>&1; then
  $KUBECTL_CMD delete namespace "$NAMESPACE" --wait=false
  echo -e "Esperando a que Kubernetes termine de purgar todos los recursos del namespace..."
  $KUBECTL_CMD wait --for=delete namespace/"$NAMESPACE" --timeout=90s 2>/dev/null || true
  echo -e "${GREEN}✓ Namespace eliminado.${NC}"
else
  echo -e "${YELLOW}Aviso: El namespace '${NAMESPACE}' ya no existía.${NC}"
fi

# 4. Eliminar datos físicos en disco
if [[ "$KEEP_DATA" == "false" ]]; then
  echo -e "${CYAN}[4/4] Eliminando datos físicos en disco (/opt/aurora-gov/${NAMESPACE})...${NC}"
  HOST_DIR="/opt/aurora-gov/${NAMESPACE}"
  if [[ -d "$HOST_DIR" ]]; then
    if [[ $EUID -ne 0 ]] && command -v sudo >/dev/null 2>&1; then
      sudo rm -rf "$HOST_DIR"
    else
      rm -rf "$HOST_DIR"
    fi
    echo -e "${GREEN}✓ Directorio ${HOST_DIR} eliminado correctamente.${NC}"
  else
    echo -e "${YELLOW}Aviso: El directorio ${HOST_DIR} no existe en este host.${NC}"
  fi
else
  echo -e "${YELLOW}[4/4] Omitido: Datos en disco conservados en /opt/aurora-gov/${NAMESPACE}.${NC}"
fi

echo ""
echo -e "${GREEN}======================================================${NC}"
echo -e "${GREEN}✓ Instancia '${NAMESPACE}' desinstalada completamente.${NC}"
echo -e "${GREEN}======================================================${NC}"
