#!/bin/bash
# monitoring/setup-monitoring.sh

set -e

# Definir variáveis
NAMESPACE="monitoring"
GRAFANA_ADMIN_PASSWORD="StrongPassword123"  # Alterar para uma senha segura

# Criar namespace se não existir
kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -

# Criar secrets para Grafana
kubectl create secret generic grafana-secrets \
  --from-literal=admin-password=${GRAFANA_ADMIN_PASSWORD} \
  --namespace=${NAMESPACE} \
  --dry-run=client -o yaml | kubectl apply -f -

# Criar PVCs para armazenamento persistente
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: prometheus-pvc
  namespace: ${NAMESPACE}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: grafana-pvc
  namespace: ${NAMESPACE}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
EOF

# Aplicar ConfigMap do Prometheus
kubectl apply -f monitoring/kubernetes/prometheus-config.yaml

# Aplicar manifestos do Prometheus e Grafana
kubectl apply -f monitoring/kubernetes/prometheus.yaml
kubectl apply -f monitoring/kubernetes/grafana.yaml

# Aguardar pods estarem prontos
echo "Aguardando pods de monitoramento estarem prontos..."
kubectl wait --for=condition=ready pod -l app=prometheus --timeout=300s -n ${NAMESPACE}
kubectl wait --for=condition=ready pod -l app=grafana --timeout=300s -n ${NAMESPACE}

# Obter URLs de acesso
PROMETHEUS_POD=$(kubectl get pods -l app=prometheus -n ${NAMESPACE} -o jsonpath="{.items[0].metadata.name}")
GRAFANA_INGRESS=$(kubectl get ingress grafana-ingress -n ${NAMESPACE} -o jsonpath="{.spec.rules[0].host}")

echo "Monitoramento configurado com sucesso!"
echo "Prometheus disponível via port-forward: kubectl port-forward ${PROMETHEUS_POD} 9090:9090 -n ${NAMESPACE}"
echo "Grafana disponível em: https://${GRAFANA_INGRESS}"
echo "Credenciais do Grafana: admin / ${GRAFANA_ADMIN_PASSWORD}"
