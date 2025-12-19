# Infrastructure SysOps - Projet de conteneurisation

## 🎯 Objectif
Déploiement automatisé d'une infrastructure container-ready pour équipes DevOps avec gestion intelligente des images Docker.

## 📋 Prérequis (installation manuelle une seule fois)
- VM Debian 12/13 ou Ubuntu 20.04+
- SSH configuré et fonctionnel  
- Git installé
- Ansible installé

## 🚀 Installation depuis zéro

### Méthode complète (nouvelle VM)
```bash
# 1. Cloner le dépôt
git clone https://github.com/antoinecombalot/sysops-infrastructure.git
cd sysops-infrastructure

# 2. V1 - Installation Docker
./scripts/deploy-v1.sh

# 3. V2 - Configuration gestionnaire d'images (après reconnexion SSH)
./scripts/docker-image-manager.sh update hello-world
./scripts/docker-image-manager.sh list
./scripts/docker-image-manager.sh test hello-world

#       - Configuration de mise à jour des Dockers automatique
./scripts/setup-docker-cron.sh "0 6 * * *" # Tous les jours à 6h du matin

