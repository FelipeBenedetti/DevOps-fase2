#!/bin/bash
# deploy/scripts/deploy-to-staging.sh

set -e

# Definir variáveis
IMAGE_TAG=$1
NAMESPACE="devops-app-staging"
APP_NAME="devops-app"
DEPLOYMENT_NAME="${APP_NAME}"
ECR_REPOSITORY="seu-account-id.dkr.ecr.us-east-1.amazonaws.com/${APP_NAME}"
IMAGE="${ECR_REPOSITORY}:${IMAGE_TAG}"

echo "Iniciando deploy em staging..."
echo "Imagem: ${IMAGE}"

# Configurar kubectl para o cluster de staging
aws eks update-kubeconfig --name devops-staging-cluster --region us-east-1

# Verificar se o namespace existe, caso contrário criar
kubectl get namespace ${NAMESPACE} > /dev/null 2>&1 || kubectl create namespace ${NAMESPACE}

# Atualizar ConfigMap com configurações de ambiente
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${APP_NAME}-config
  namespace: ${NAMESPACE}
data:
  FLASK_ENV: "staging"
  LOG_LEVEL: "INFO"
EOF

# Gerar manifesto de deployment a partir do template
sed -e "s|{{IMAGE}}|${IMAGE}|g" \
    -e "s|{{APP_NAME}}|${APP_NAME}|g" \
    -e "s|{{NAMESPACE}}|${NAMESPACE}|g" \
    deploy/templates/deployment.yaml.tmpl > deploy/kubernetes/staging/deployment.yaml

# Aplicar manifesto de deployment
kubectl apply -f deploy/kubernetes/staging/deployment.yaml -n ${NAMESPACE}

# Aplicar manifesto de service (se não existir)
kubectl apply -f deploy/kubernetes/staging/service.yaml -n ${NAMESPACE}

# Aplicar manifesto de ingress (se não existir)
kubectl apply -f deploy/kubernetes/staging/ingress.yaml -n ${NAMESPACE}

# Aguardar o rollout do deployment
echo "Aguardando rollout do deployment..."
kubectl rollout status deployment/${DEPLOYMENT_NAME} -n ${NAMESPACE} --timeout=300s

# Verificar se o deploy foi bem-sucedido
AVAILABLE_REPLICAS=$(kubectl get deployment ${DEPLOYMENT_NAME} -n ${NAMESPACE} -o jsonpath='{.status.availableReplicas}')
DESIRED_REPLICAS=$(kubectl get deployment ${DEPLOYMENT_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.replicas}')

if [ "${AVAILABLE_REPLICAS}" == "${DESIRED_REPLICAS}" ]; then
  echo "Deploy em staging concluído com sucesso!"
  
  # Obter URL da aplicação
  INGRESS_HOST=$(kubectl get ingress ${APP_NAME}-ingress -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  echo "Aplicação disponível em: https://${INGRESS_HOST}"
  
  exit 0
else
  echo "Falha no deploy em staging. Replicas disponíveis: ${AVAILABLE_REPLICAS}/${DESIRED_REPLICAS}"
  exit 1
fi
