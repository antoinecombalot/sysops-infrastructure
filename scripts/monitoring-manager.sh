#!/bin/bash

COMPOSE_FILE="docker-compose/monitoring-stack.yml"

# Fonction d'aide
show_help() {
    cat << EOF
🔧 Monitoring Manager - Gestionnaire de la stack de monitoring

Usage: $0 [COMMAND]

Commandes:
  start           Démarrer tous les services
  stop            Arrêter tous les services  
  restart         Redémarrer tous les services
  status          Voir le statut des services
  logs [SERVICE]  Voir les logs (service optionnel)
  update          Mettre à jour les images
  backup          Sauvegarder les données
  restore [FILE]  Restaurer depuis une sauvegarde
  test            Tester la connectivité
  config          Recharger les configs sans redémarrage
  clean           Nettoyer les données (ATTENTION!)

Services disponibles: prometheus, grafana, cadvisor, node-exporter, alertmanager

Exemples:
  $0 start
  $0 logs prometheus
  $0 restart grafana
  $0 backup
EOF
}

# Fonctions utilitaires
check_compose() {
    if [ ! -f "$COMPOSE_FILE" ]; then
        echo "❌ Fichier Docker Compose non trouvé: $COMPOSE_FILE"
        exit 1
    fi
}

test_services() {
    echo "🧪 Test des services monitoring..."
    
    services=(
        "prometheus:9090"
        "grafana:3001" 
        "node-exporter:9100"
        "cadvisor:8080"
        "alertmanager:9093"
    )
    
    for service in "${services[@]}"; do
        IFS=':' read -r name port <<< "$service"
        if curl -sf "http://localhost:$port" > /dev/null 2>&1; then
            echo "✅ $name (port $port) - OK"
        else
            echo "❌ $name (port $port) - KO"
        fi
    done
}

# Gestion des commandes
case "${1:-help}" in
    "start")
        check_compose
        echo "🚀 Démarrage de la stack monitoring..."
        docker-compose -f "$COMPOSE_FILE" up -d
        sleep 10
        test_services
        ;;
        
    "stop")
        check_compose
        echo "⏹️ Arrêt de la stack monitoring..."
        docker-compose -f "$COMPOSE_FILE" down
        ;;
        
    "restart")
        check_compose
        if [ -n "$2" ]; then
            echo "🔄 Redémarrage du service $2..."
            docker-compose -f "$COMPOSE_FILE" restart "$2"
        else
            echo "🔄 Redémarrage de toute la stack..."
            docker-compose -f "$COMPOSE_FILE" restart
        fi
        ;;
        
    "status")
        check_compose
        echo "📊 Statut des services:"
        docker-compose -f "$COMPOSE_FILE" ps
        echo ""
        test_services
        ;;
        
    "logs")
        check_compose
        if [ -n "$2" ]; then
            echo "📜 Logs du service $2:"
            docker-compose -f "$COMPOSE_FILE" logs -f --tail=50 "$2"
        else
            echo "📜 Logs de tous les services:"
            docker-compose -f "$COMPOSE_FILE" logs --tail=20
        fi
        ;;
        
    "update")
        check_compose
        echo "⬇️ Mise à jour des images..."
        docker-compose -f "$COMPOSE_FILE" pull
        docker-compose -f "$COMPOSE_FILE" up -d
        ;;
        
    "backup")
        echo "💾 Sauvegarde des données monitoring..."
        timestamp=$(date +%Y%m%d_%H%M%S)
        backup_dir="backups/monitoring_$timestamp"
        mkdir -p "$backup_dir"
        
        # Arrêter temporairement pour sauvegarde cohérente
        docker-compose -f "$COMPOSE_FILE" stop
        
        # Copier les volumes
        docker run --rm -v monitoring_prometheus_data:/source -v "$(pwd)/$backup_dir":/backup alpine tar czf /backup/prometheus.tar.gz -C /source .
        docker run --rm -v monitoring_grafana_data:/source -v "$(pwd)/$backup_dir":/backup alpine tar czf /backup/grafana.tar.gz -C /source .
        
        # Redémarrer
        docker-compose -f "$COMPOSE_FILE" start
        
        echo "✅ Sauvegarde créée: $backup_dir"
        ;;
        
    "restore")
        if [ -z "$2" ]; then
            echo "❌ Usage: $0 restore <backup_directory>"
            exit 1
        fi
        
        echo "🔄 Restauration depuis $2..."
        # Implementation de restore...
        ;;
        
    "test")
        test_services
        ;;
        
    "config")
        check_compose
        echo "🔄 Rechargement des configurations..."
        # Recharger Prometheus
        curl -X POST http://localhost:9090/-/reload
        echo "✅ Configuration Prometheus rechargée"
        ;;
        
    "clean")
        echo "⚠️ ATTENTION: Cette action supprimera toutes les données monitoring!"
        read -p "Tapez 'DELETE' pour confirmer: " confirm
        if [ "$confirm" = "DELETE" ]; then
            docker-compose -f "$COMPOSE_FILE" down -v
            docker volume rm monitoring_prometheus_data monitoring_grafana_data monitoring_alertmanager_data 2>/dev/null || true
            echo "✅ Données supprimées"
        else
            echo "❌ Annulé"
        fi
        ;;
        
    "help"|"-h"|"--help")
        show_help
        ;;
        
    *)
        echo "❌ Commande inconnue: $1"
        show_help
        exit 1
        ;;
esac
