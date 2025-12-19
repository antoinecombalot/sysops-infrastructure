#!/bin/bash

set -e

echo "🚀 DÉPLOIEMENT V3 - Stack Monitoring (Prometheus + Grafana)"
echo "==========================================================="

# Répertoire de travail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "📁 Répertoire projet: $PROJECT_DIR"

# Vérification des prérequis
echo "🔍 Vérification des prérequis V3..."

if ! command -v docker &> /dev/null; then
    echo "❌ Docker n'est pas installé. Exécutez d'abord deploy-v1.sh"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose n'est pas disponible"
    exit 1
fi

# Aller dans le répertoire docker-compose
cd "$PROJECT_DIR/docker-compose"

# Vérifier que les fichiers de config existent
echo "🔍 Vérification des fichiers de configuration..."

required_files=(
    "monitoring/prometheus/prometheus.yml"
    "monitoring/prometheus/alerts.yml"
    "monitoring/alertmanager/alertmanager.yml"
    "monitoring/grafana/provisioning/datasources/prometheus.yml"
    "monitoring/grafana/provisioning/dashboards/dashboard.yml"
)

missing_files=()
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -gt 0 ]; then
    echo "❌ Fichiers de configuration manquants:"
    printf '%s\n' "${missing_files[@]}"
    echo ""
    echo "🔧 Création des fichiers manquants..."
    
    # Créer les dossiers
    mkdir -p monitoring/{prometheus,grafana/{dashboards,provisioning/{dashboards,datasources}},alertmanager}
    
    # Créer prometheus.yml si manquant
    if [ ! -f "monitoring/prometheus/prometheus.yml" ]; then
        cat > monitoring/prometheus/prometheus.yml << 'PROM_EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
PROM_EOF
    fi
    
    # Créer alerts.yml si manquant
    if [ ! -f "monitoring/prometheus/alerts.yml" ]; then
        echo "groups: []" > monitoring/prometheus/alerts.yml
    fi
    
    # Créer alertmanager.yml si manquant
    if [ ! -f "monitoring/alertmanager/alertmanager.yml" ]; then
        cat > monitoring/alertmanager/alertmanager.yml << 'ALERT_EOF'
global:
route:
  receiver: 'web.hook'
receivers:
  - name: 'web.hook'
ALERT_EOF
    fi
    
    # Créer datasource Grafana si manquant
    if [ ! -f "monitoring/grafana/provisioning/datasources/prometheus.yml" ]; then
        cat > monitoring/grafana/provisioning/datasources/prometheus.yml << 'GRAF_EOF'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
GRAF_EOF
    fi
    
    # Créer config dashboard si manquant
    if [ ! -f "monitoring/grafana/provisioning/dashboards/dashboard.yml" ]; then
        cat > monitoring/grafana/provisioning/dashboards/dashboard.yml << 'DASH_EOF'
apiVersion: 1
providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    options:
      path: /var/lib/grafana/dashboards
DASH_EOF
    fi
    
    echo "✅ Fichiers de configuration créés"
fi

# Créer le réseau externe pour les applications
echo "🔗 Création du réseau Docker pour applications..."
docker network create app-network 2>/dev/null || echo "Réseau app-network déjà existant"

# Arrêter d'éventuels services existants
echo "🛑 Arrêt des services existants..."
docker-compose -f monitoring-stack.yml down 2>/dev/null || true

# Démarrer la stack
echo "📊 Déploiement de la stack monitoring..."
docker-compose -f monitoring-stack.yml up -d

# Attendre que les services démarrent
echo "⏳ Attente du démarrage des services (30s)..."
sleep 30

# Vérification des services
echo "🔍 Vérification des services..."
docker-compose -f monitoring-stack.yml ps

# Tests de connectivité
echo "🧪 Tests de connectivité..."

test_service() {
    local service_name="$1"
    local port="$2"
    local path="${3:-/}"
    
    echo -n "Testing $service_name... "
    if curl -sf "http://localhost:$port$path" > /dev/null 2>&1; then
        echo "✅ OK"
        return 0
    else
        echo "❌ KO"
        return 1
    fi
}

# Test des services
test_service "Prometheus" "9090" "/-/healthy"
test_service "Grafana" "3001" "/api/health"
test_service "Node Exporter" "9100" "/metrics"
test_service "cAdvisor" "8080" "/metrics"
test_service "AlertManager" "9093" "/-/healthy"

echo ""
echo "🎉 V3 DÉPLOYÉE AVEC SUCCÈS !"
echo "=========================="
echo "🔗 Accès aux services:"
echo "   📊 Grafana:     http://localhost:3001 (admin/sysops2024)"
echo "   📈 Prometheus:  http://localhost:9090"
echo "   🚨 AlertManager: http://localhost:9093"
echo "   🐳 cAdvisor:    http://localhost:8080"
echo "   💻 Node Metrics: http://localhost:9100"
echo ""
echo "📋 Gestion:"
echo "   ./scripts/monitoring-manager.sh status"
echo "   ./scripts/monitoring-manager.sh logs"
echo "   ./scripts/monitoring-manager.sh restart"
echo ""
echo "📁 Configuration: docker-compose/monitoring/"
echo "📜 Logs détaillés: docker-compose -f docker-compose/monitoring-stack.yml logs"

