#!/bin/bash

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/../config/docker-images.conf"
LOG_FILE="/opt/logs/docker-updates.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction de logging colorée
log() {
    local level="$1"
    shift
    local message="$*"
    
    case "$level" in
        "INFO")  echo -e "${BLUE}[INFO]${NC} $message" | tee -a "$LOG_FILE" ;;
        "WARN")  echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$LOG_FILE" ;;
        "ERROR") echo -e "${RED}[ERROR]${NC} $message" | tee -a "$LOG_FILE" ;;
        "SUCCESS") echo -e "${GREEN}[SUCCESS]${NC} $message" | tee -a "$LOG_FILE" ;;
    esac
}

# Créer le fichier de configuration par défaut
create_default_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    cat > "$CONFIG_FILE" << 'EOC'
# Configuration des images Docker à maintenir
# Format: IMAGE_NAME:TAG:ENABLED:TEST_COMMAND
# TEST_COMMAND est optionnel

# Images de test
hello-world:latest:true:
hello-world:linux:true:

# Images courantes (exemples - décommenter si nécessaire)
#nginx:latest:true:nginx -t
#postgres:13:false:
#redis:alpine:false:redis-server --version
#node:18-alpine:false:node --version

# Images personnalisées (à adapter)
#monapp/frontend:latest:true:
#monapp/backend:latest:true:curl -f http://localhost:3000/health
EOC

    log "INFO" "Fichier de configuration créé: $CONFIG_FILE"
}

# Lire la configuration
read_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log "WARN" "Fichier de config inexistant, création..."
        create_default_config
    fi
    
    grep -v '^#' "$CONFIG_FILE" | grep -v '^$'
}

# Fonction de mise à jour d'une image
update_single_image() {
    local image_spec="$1"
    
    # Parser la configuration
    IFS=':' read -r image_name tag enabled test_cmd <<< "$image_spec"
    
    if [ "$enabled" != "true" ]; then
        log "INFO" "⏭️ $image_name:$tag - désactivé"
        return 0
    fi
    
    local full_image="$image_name:$tag"
    
    log "INFO" "🔍 Traitement de $full_image"
    
    # Obtenir l'ID actuel
    local current_id=""
    if docker images "$full_image" --format "{{.ID}}" 2>/dev/null | grep -q .; then
        current_id=$(docker images "$full_image" --format "{{.ID}}" 2>/dev/null | head -1)
    fi
    
    # Pull de la nouvelle version
    log "INFO" "⬇️ Pull $full_image..."
    if docker pull "$full_image" > /dev/null 2>&1; then
        local new_id=$(docker images "$full_image" --format "{{.ID}}" | head -1)
        
        if [ "$current_id" != "$new_id" ]; then
            log "SUCCESS" "🆕 $full_image mis à jour ($current_id -> $new_id)"
            
            # Test si spécifié
            if [ -n "$test_cmd" ]; then
                log "INFO" "🧪 Test: docker run --rm $full_image $test_cmd"
                if docker run --rm "$full_image" $test_cmd > /dev/null 2>&1; then
                    log "SUCCESS" "✅ Test réussi pour $full_image"
                else
                    log "ERROR" "❌ Test échoué pour $full_image"
                fi
            fi
        else
            log "INFO" "📌 $full_image déjà à jour"
        fi
    else
        log "ERROR" "❌ Échec pull $full_image"
        return 1
    fi
}

# Mise à jour de toutes les images configurées
update_all_images() {
    log "INFO" "🚀 Début mise à jour automatique des images Docker"
    
    local success_count=0
    local error_count=0
    
    while IFS= read -r line; do
        if update_single_image "$line"; then
            ((success_count++))
        else
            ((error_count++))
        fi
    done < <(read_config)
    
    log "INFO" "📊 Résumé: $success_count succès, $error_count erreurs"
    
    # Nettoyage
    if [ "${SKIP_CLEANUP:-false}" != "true" ]; then
        log "INFO" "🧹 Nettoyage système..."
        docker system prune -f > /dev/null 2>&1
        log "SUCCESS" "✅ Nettoyage terminé"
    fi
}

# Afficher les images configurées
list_images() {
    echo "📋 Images configurées dans $CONFIG_FILE:"
    echo "========================================"
    
    while IFS=':' read -r image tag enabled test_cmd; do
        local status="❌ Désactivé"
        [ "$enabled" = "true" ] && status="✅ Activé"
        
        printf "%-30s %-10s %s\n" "$image:$tag" "$status" "${test_cmd:-(aucun test)}"
    done < <(read_config)
}

# Test d'une image spécifique
test_image() {
    local image="$1"
    local tag="${2:-latest}"
    local full_image="$image:$tag"
    
    log "INFO" "🧪 Test de $full_image"
    
    if docker run --rm "$full_image" > /dev/null 2>&1; then
        log "SUCCESS" "✅ $full_image fonctionne"
        return 0
    else
        log "ERROR" "❌ $full_image ne fonctionne pas"
        return 1
    fi
}

# Aide
show_help() {
    cat << EOF
🐳 Docker Image Manager - Gestionnaire automatique d'images

Usage: $0 [COMMAND] [OPTIONS]

Commandes:
  update [IMAGE]     Mettre à jour toutes les images ou une image spécifique
  list              Lister les images configurées  
  test IMAGE [TAG]  Tester une image
  config            Afficher le chemin du fichier de configuration
  help              Afficher cette aide

Exemples:
  $0 update                    # Mettre à jour toutes les images
  $0 update hello-world        # Mettre à jour seulement hello-world
  $0 list                      # Voir les images configurées
  $0 test hello-world          # Tester hello-world:latest
  $0 test nginx 1.21           # Tester nginx:1.21

Fichier de configuration: $CONFIG_FILE
Fichier de log: $LOG_FILE

Variables d'environnement:
  SKIP_CLEANUP=true           # Éviter le nettoyage automatique
  LOG_FILE=/custom/path.log   # Fichier de log personnalisé

EOF
}

# Créer les dossiers nécessaires
mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$CONFIG_FILE")"

# Gestion des commandes
case "${1:-update}" in
    "update")
        if [ -n "$2" ]; then
            # Mise à jour d'une image spécifique
            image_line=$(read_config | grep "^$2:" | head -1)
            if [ -n "$image_line" ]; then
                update_single_image "$image_line"
            else
                log "ERROR" "Image $2 non trouvée dans la configuration"
                exit 1
            fi
        else
            # Mise à jour de toutes les images
            update_all_images
        fi
        ;;
    "list")
        list_images
        ;;
    "test")
        if [ -z "$2" ]; then
            log "ERROR" "Usage: $0 test IMAGE [TAG]"
            exit 1
        fi
        test_image "$2" "$3"
        ;;
    "config")
        echo "Fichier de configuration: $CONFIG_FILE"
        echo "Fichier de log: $LOG_FILE"
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        log "ERROR" "Commande inconnue: $1"
        show_help
        exit 1
        ;;
esac
