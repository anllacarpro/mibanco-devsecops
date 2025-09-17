#!/bin/bash

# Script para cleanup de recursos Azure del challenge Mibanco DevSecOps
echo "🧹 Iniciando cleanup de recursos Azure..."

# Variables
SUBSCRIPTION_ID="97d71227-cecf-47e5-8c90-da0bb330fb7c"
RESOURCE_GROUP_PATTERN="mibanco-devsecops-*-rg"

# Buscar resource group
RG_NAME=$(az group list --subscription $SUBSCRIPTION_ID --query "[?contains(name,'mibanco-devsecops')].name" -o tsv | head -n1)

if [ -z "$RG_NAME" ]; then
    echo "❌ No se encontró el resource group"
    exit 1
fi

echo "📋 Resource Group encontrado: $RG_NAME"

# Listar recursos antes de eliminar
echo "📊 Recursos a eliminar:"
az resource list -g $RG_NAME --query "[].{Name:name, Type:type}" -o table

# Confirmación
read -p "¿Está seguro de eliminar todos los recursos? (y/N): " confirm
if [[ $confirm != [yY] ]]; then
    echo "❌ Operación cancelada"
    exit 0
fi

# Eliminar resource group (elimina todos los recursos contenidos)
echo "🗑️ Eliminando resource group: $RG_NAME"
az group delete --name $RG_NAME --yes --no-wait

echo "✅ Cleanup iniciado. Los recursos se eliminarán en background."
echo "📝 Para verificar el estado: az group show --name $RG_NAME"