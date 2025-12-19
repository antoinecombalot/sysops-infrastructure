# Infrastructure SysOps - Projet de conteneurisation

## 🎯 Objectif
Déploiement automatisé d'une infrastructure container-ready complète pour équipes DevOps avec monitoring professionnel intégré.

## 📋 Prérequis (installation manuelle une seule fois)
- VM Debian 12/13 ou Ubuntu 20.04+
- SSH configuré et fonctionnel  
- Git installé
- Ansible installé

## 🚀 Installation complète depuis zéro

### Déploiement automatique complet
```bash
# 1. Cloner le dépôt
git clone https://github.com/VOTRE_USERNAME/sysops-infrastructure.git
cd sysops-infrastructure

# 2. V1 - Installation Docker
./scripts/deploy-v1.sh
# Redémarrer session SSH après V1

# 3. V2 - Gestionnaire d'images Docker
./scripts/docker-image-manager.sh update

# 4. V3 - Stack monitoring complète
./scripts/deploy-v3.sh
