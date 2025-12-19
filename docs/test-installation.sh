#!/bin/bash

echo "🧪 TESTS POST-INSTALLATION V3"
echo "============================="

# V1 - Docker
echo "1. Tests Docker (V1):"
docker --version
docker-compose --version
docker run --rm hello-world > /dev/null && echo "✅ Docker OK" || echo "❌ Docker KO"

# V2 - Image Manager  
echo "2. Tests Image Manager (V2):"
./scripts/docker-image-manager.sh config > /dev/null && echo "✅ Manager OK" || echo "❌ Manager KO"

# V3 - Monitoring
echo "3. Tests Stack Monitoring (V3):"
services=("prometheus:9090" "grafana:3001" "cadvisor:8080" "node-exporter:9100" "alertmanager:9093")

for service in "${services[@]}"; do
    IFS=':' read -r name port <<< "$service"
    if curl -sf "http://localhost:$port" > /dev/null 2>&1; then
        echo "✅ $name OK"
    else
        echo "❌ $name KO"
    fi
done

echo "4. Volumes Docker:"
docker volume ls | grep monitoring && echo "✅ Volumes OK" || echo "❌ Volumes manquants"

echo "5. Réseaux Docker:"
docker network ls | grep monitoring && echo "✅ Réseaux OK" || echo "❌ Réseaux manquants"

echo ""
echo "🎯 Installation testée !"
