#!/bin/bash

# Script pour configurer la mise à jour automatique via cron

CRON_TIME="${1:-0 2 * * *}"  # Par défaut: tous les jours à 2h du matin
SCRIPT_PATH="$(realpath "$(dirname "$0")/docker-image-manager.sh")"

echo "🕒 Configuration de la mise à jour automatique Docker"
echo "Script: $SCRIPT_PATH"
echo "Horaire: $CRON_TIME"

# Ajouter la tâche cron
(crontab -l 2>/dev/null; echo "$CRON_TIME $SCRIPT_PATH update >> /opt/logs/docker-cron.log 2>&1") | crontab -

echo "✅ Tâche cron ajoutée"
echo "📋 Voir les tâches: crontab -l"
echo "📁 Logs cron: /opt/logs/docker-cron.log"

# Créer le dossier de logs
mkdir -p /opt/logs

# Test immédiat
echo "🧪 Test du script..."
"$SCRIPT_PATH" list
