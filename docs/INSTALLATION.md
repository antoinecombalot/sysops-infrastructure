# Guide d'installation complète - Infrastructure SysOps V3

## 🎯 Installation V1 → V2 → V3 depuis zéro

### Prérequis VM
- Debian 12/13 ou Ubuntu 20.04+
- 6GB RAM minimum, 8GB recommandé (monitoring consomme ~2GB)
- 80GB disque libre minimum
- Accès internet pour téléchargements Docker

### Étape 1 : Préparation manuelle (une seule fois)
```bash
# Mise à jour système
sudo apt update && sudo apt upgrade -y

# Installation des outils de base
sudo apt install -y git ssh openssh-server curl wget

# Installation Ansible
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

# Vérification versions
git --version
ssh -V  
ansible --version
docker --version 2>/dev/null || echo "Docker sera installé en V1"
Étape 2 : Clonage et V1 (Docker)
# Cloner le dépôt
git clone https://github.com/VOTRE_USERNAME/sysops-infrastructure.git
cd sysops-infrastructure

# V1 - Installation Docker automatisée
./scripts/deploy-v1.sh

# ⚠️ IMPORTANT: Redémarrer session SSH
exit
# Reconnectez-vous en SSH

# Test Docker
docker run --rm hello-world
Étape 3 : V2 (Docker Image Manager)
# Configuration et première mise à jour
./scripts/docker-image-manager.sh list
./scripts/docker-image-manager.sh update

# Test du gestionnaire
./scripts/docker-image-manager.sh test hello-world

# Configuration automatisation (optionnel)
./scripts/setup-docker-cron.sh "0 6 * * *"
Étape 4 : V3 (Stack Monitoring) 🆕
# Déploiement stack monitoring complète
./scripts/deploy-v3.sh

# Vérification des services
./scripts/monitoring-manager.sh status

# Tests des interfaces web
curl -s http://localhost:9090/-/healthy  # Prometheus
curl -s http://localhost:3001/api/health # Grafana
Étape 5 : Configuration initiale monitoring
# 1. Accès Grafana
firefox http://localhost:3001 &
# Login: admin / Password: sysops2024

# 2. Vérification Prometheus
firefox http://localhost:9090 &

# 3. Test AlertManager  
firefox http://localhost:9093 &
