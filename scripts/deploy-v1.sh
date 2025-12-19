#!/bin/bash

set -e  # Arrêt en cas d'erreur

echo "🚀 DÉPLOIEMENT V1 - Installation automatisée de Docker"
echo "=================================================="

# Vérification des prérequis
echo "🔍 Vérification des prérequis..."

if ! command -v ansible &> /dev/null; then
    echo "❌ Erreur: Ansible n'est pas installé"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "❌ Erreur: Git n'est pas installé"
    exit 1
fi

echo "✅ Ansible version: $(ansible --version | head -n1)"
echo "✅ Git version: $(git --version)"

# Vérification de l'inventaire
if [ ! -f "ansible/inventories/local.yml" ]; then
    echo "❌ Erreur: Fichier d'inventaire introuvable"
    exit 1
fi

# Test de connectivité Ansible
echo "🔗 Test de connectivité Ansible..."
if ! ansible -i ansible/inventories/local.yml all -m ping; then
    echo "❌ Erreur: Impossible de se connecter via Ansible"
    exit 1
fi

# Exécution du playbook
echo "📦 Lancement de l'installation Docker..."
ansible-playbook -i ansible/inventories/local.yml ansible/playbooks/install-docker.yml

# Vérifications finales
echo ""
echo "🏁 VÉRIFICATIONS FINALES"
echo "========================"

echo "🐳 Docker installé:"
docker --version

echo "🐙 Docker Compose (plugin):"
docker compose version

echo "🐙 Docker Compose (standalone):"
docker-compose --version

echo "👥 Utilisateurs dans le groupe docker:"
getent group docker

echo ""
echo "✅ V1 TERMINÉE AVEC SUCCÈS !"
echo "============================="
echo "⚠️  IMPORTANT: Redémarrez votre session SSH pour que les permissions Docker prennent effet"
echo "💡 Test rapide après reconnexion: docker run --rm hello-world"

