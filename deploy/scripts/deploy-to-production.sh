#!/bin/bash
# deploy/scripts/deploy-to-production.sh

set -e

# Definir variáveis
IMAGE_TAG=$1
NAMESPACE="devops-app-production"
APP_NAME="devops-app"
ECR_REPOSITORY="seu-account-id.dkr.ecr.us-east-1.amazonaws.com/${APP_NAME}"
IMAGE="${ECR_REPOSITORY}:${IMAGE_TAG}"

echo "Iniciando deploy em produção usando estratégia Blue-Green..."
echo "Imagem: ${IMAGE}"

# Configurar kubectl para o cluster de produção
aws eks update-kubeconfig --name devops-production-cluster --region us-east-1

# Verificar se o namespace existe, caso contrário criar
kubectl get namespace ${NAMESPACE} > /dev/null 2>&1 || kubectl create namespace ${NAMESPACE}

# Determinar qual deployment está ativo (blue ou green)
ACTIVE_DEPLOYMENT=$(kubectl get service ${APP_NAME}-service -n ${NAMESPACE} -o jsonpath='{.spec.selector.deployment}' 2>/dev/null || echo "blue")

if [ "${ACTIVE_DEPLOYMENT}" == "blue" ]; then
  INACTIVE_DEPLOYMENT="green"
else
  INACTIVE_DEPLOYMENT="blue"
fi

echo "Deployment ativo: ${ACTIVE_DEPLOYMENT}"
echo "Deployment inativo que será atualizado: ${INACTIVE_DEPLOYMENT}"

# Atualizar ConfigMap com configurações de ambiente
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${APP_NAME}-config
  namespace: ${NAMESPACE}
data:
  FLASK_ENV: "production"
  LOG_LEVEL: "WARNING"
EOF

# Gerar manifesto de deployment para o ambiente inativo
sed -e "s|{{IMAGE}}|${IMAGE}|g" \
    -e "s|{{APP_NAME}}|${APP_NAME}|g" \
    -e "s|{{DEPLOYMENT}}|${INACTIVE_DEPLOYMENT}|g" \
    -e "s|{{NAMESPACE}}|${NAMESPACE}|g" \
    deploy/templates/deployment-blue-green.yaml.tmpl > deploy/kubernetes/production/deployment-${INACTIVE_DEPLOYMENT}.yaml

# Aplicar manifesto de deployment para o ambiente inativo
kubectl apply -f deploy/kubernetes/production/deployment-${INACTIVE_DEPLOYMENT}.yaml -n ${NAMESPACE}

# Aguardar o rollout do deployment inativo
echo "Aguardando rollout do deployment ${INACTIVE_DEPLOYMENT}..."
kubectl rollout status deployment/${APP_NAME}-${INACTIVE_DEPLOYMENT} -n ${NAMESPACE} --timeout=300s

# Verificar se o deploy foi bem-sucedido
AVAILABLE_REPLICAS=$(kubectl get deployment ${APP_NAME}-${INACTIVE_DEPLOYMENT} -n ${NAMESPACE} -o jsonpath='{.status.availableReplicas}')
DESIRED_REPLICAS=$(kubectl get deployment ${APP_NAME}-${INACTIVE_DEPLOYMENT} -n ${NAMESPACE} -o jsonpath='{.spec.replicas}')

if [ "${AVAILABLE_REPLICAS}" == "${DESIRED_REPLICAS}" ]; then
  echo "Deploy do ambiente ${INACTIVE_DEPLOYMENT} concluído com sucesso!"
  
  # Executar testes no novo ambiente antes de alternar o tráfego
  echo "Executando testes no novo ambiente..."
  # Aqui você pode adicionar chamadas para scripts de teste
  
  # Alternar o tráfego para o novo ambiente
  echo "Alternando tráfego para o ambiente ${INACTIVE_DEPLOYMENT}..."
  kubectl patch service ${APP_NAME}-service -n ${NAMESPACE} -p "{\"spec\":{\"selector\":{\"deployment\":\"${INACTIVE_DEPLOYMENT}\"}}}"
  
  echo "Tráfego alternado com sucesso para o ambiente ${INACTIVE_DEPLOYMENT}!"
  
  # Obter URL da aplicação
  INGRESS_HOST=$(kubectl get ingress ${APP_NAME}-ingress -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
  echo "Aplicação disponível em: https://${INGRESS_HOST}"
  
  exit 0
else
  echo "Falha no deploy do ambiente ${INACTIVE_DEPLOYMENT}. Replicas disponíveis: ${AVAILABLE_REPLICAS}/${DESIRED_REPLICAS}"
  exit 1
fi
