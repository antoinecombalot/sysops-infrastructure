# Infrastructure SysOps - Projet de conteneurisation

## 🎯 Objectif
Déploiement automatisé d'une infrastructure container-ready pour équipes DevOps.

## 📋 Prérequis (installation manuelle)
- VM Ubuntu 20.04 LTS ou plus récent
- SSH configuré et fonctionnel
- Git installé
- Ansible installé

## 🚀 Installation depuis zéro

### Nouvelle VM ou réinstallation complète
```bash
# Cloner le dépôt
git clone https://github.com/VOTRE_USERNAME/sysops-infrastructure.git
cd sysops-infrastructure

# V1 - Installation Docker
./scripts/deploy-v1.sh
