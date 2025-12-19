# Guide utilisateur - Stack Monitoring V3

## 🎯 Vue d'ensemble
La V3 fournit une stack de monitoring complète basée sur Prometheus + Grafana pour surveiller votre infrastructure conteneurisée.

## 🏗️ Architecture monitoring
┌─────────────────┐ ┌──────────────────┐ ┌─────────────────┐ │ Applications │ │ Métriques │ │ Visualisation │ │ │ │ │ │ │ │ Your Apps │───▶│ Prometheus │───▶│ Grafana │ │ Docker │ │ cAdvisor │ │ Dashboards │
│ System │ │ Node Exporter │ │ Alerts │ └─────────────────┘ └──────────────────┘ └─────────────────┘ │ ▼ ┌─────────────────┐ │ AlertManager │ │ Notifications │ └─────────────────┘


## 🚀 Démarrage rapide

### Installation
```bash
# Déployer la stack complète
./scripts/deploy-v3.sh

# Vérifier le statut
./scripts/monitoring-manager.sh status
