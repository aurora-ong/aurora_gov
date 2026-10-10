#!/usr/bin/env bash

set -e

echo "=== Preparando ambiente Aurora BETA ==="

# Password por defecto para todos los usuarios cargados por el seed BETA
export AURORA_BETA_DEFAULT_PASSWORD="123456"

echo "Instalando dependencias..."
mix deps.get

echo "Preparando proyecto..."
mix setup

echo "Reseteando bases de datos..."
cd apps/aurora_gov
mix db.reset

echo "Cargando modelo Aurora BETA..."
mix db.seeds

cd ../..

echo
echo "=== Aurora BETA instalada correctamente ==="
echo "Password de usuarios BETA: $AURORA_BETA_DEFAULT_PASSWORD"
echo
echo "Para iniciar la aplicación:"
echo "iex -S mix phx.server"