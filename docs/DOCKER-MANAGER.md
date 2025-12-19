# Guide utilisateur - Docker Image Manager

## 🎯 Vue d'ensemble
Le Docker Image Manager automatise la gestion des images Docker avec mise à jour intelligente, tests automatiques et configuration centralisée.

## 🚀 Démarrage rapide

### 1. Configuration initiale
```bash
# Le script crée automatiquement la configuration par défaut
./scripts/docker-image-manager.sh list

# Mettre à jour toutes les images configurées
./scripts/docker-image-manager.sh update

# Tester une image spécifique
./scripts/docker-image-manager.sh test hello-world
