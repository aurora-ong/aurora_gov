# AuroraGov - Guía de Configuración de Jobs en Helm

El chart permite control granular para decidir si los Jobs de **Base de Datos** se ejecutan en **Instalación (`onCreate`)**, en **Actualización (`onUpgrade`)**, en ambos, o en ninguno.

---

## ⚙️ Configuración en `values.yaml`

### 1. DB Reset (`dbReset`)
Ejecuta `AuroraGov.Release.db_reset` (elimina, recrea y migra la base de datos).
* En `onCreate`: Hook `post-install` (después de desplegar PostgreSQL).
* En `onUpgrade`: Hook `pre-upgrade` (antes de desplegar la nueva aplicación, cortando sesiones activas).

```yaml
dbReset:
  enabled: true      # Debe estar en true para que se considere
  onCreate: true     # Ejecutar al crear / instalar por primera vez
  onUpgrade: false   # Ejecutar al actualizar (CUIDADO: borra la BD existente)
```

**Ejemplos de uso con CLI:**
```bash
# Activar reset solo en instalación inicial:
helm install aurora-gov ... --set dbReset.enabled=true --set dbReset.onCreate=true --set dbReset.onUpgrade=false

# Forzar reset durante un upgrade específico:
helm upgrade aurora-gov ... --set dbReset.enabled=true --set dbReset.onUpgrade=true
```

---

### 2. Seeds (`seed`)
Ejecuta `AuroraGov.Release.db_seed` con el archivo especificado.
* En `onCreate`: Hook `post-install` (prioridad 10, después de migraciones).
* En `onUpgrade`: Hook `post-upgrade`.

```yaml
seed:
  enabled: true
  name: "seeds.exs" # Nombre del archivo en priv/repo
  onCreate: true    # Cargar seeds al crear la instancia
  onUpgrade: false  # Cargar seeds en cada actualización
```

**Ejemplos de uso con CLI:**
```bash
# Cargar seeds solo al crear la instancia (comportamiento por defecto):
helm install aurora-gov ... --set seed.name="seeds.exs"

# Cargar seeds también durante un upgrade:
helm upgrade aurora-gov ... --set seed.name="seeds.exs" --set seed.onUpgrade=true
```

---

### 3. Migración Automática (`migration`)
Ejecuta `AuroraGov.Release.db_create` y `AuroraGov.Release.db_migrate` (idempotente).

```yaml
migration:
  enabled: true
  onCreate: true   # default: true (post-install)
  onUpgrade: true  # default: true (post-upgrade)
```

---

## 📦 Empaquetado y Publicación (`v0.1.5`)

```bash
cd deploy/helm

# 1. Empaquetar
microk8s helm package chart/

# 2. Subir al registro OCI
microk8s helm push aurora-gov-0.1.5.tgz oci://registry.weychafe.nicher.cl/charts
```

---

## 🗑️ Desinstalación Completa (`delete_weychafe.sh`)

Para purgar una instancia sin dejar residuos (borra release de Helm, PVs huérfanos, Namespace y datos en disco `/opt/aurora-gov/<namespace>`):

```bash
# Dar permisos de ejecución
chmod +x ./deploy/helm/delete_weychafe.sh

# Desinstalación interactiva
./delete_weychafe.sh aurora-gov-demo

# Desinstalación desatendida / automatizada (-y)
./delete_weychafe.sh -n aurora-gov-demo -y

# Conservar datos en disco pero eliminar pods y recursos de k8s
./delete_weychafe.sh -n aurora-gov-demo --keep-data
```
