#!/bin/bash
# scripts/rollback.sh

set -e

# Definir variáveis
NAMESPACE=$1
APP_NAME="devops-app"
DEPLOYMENT_TYPE=$2  # "blue-green" ou "canary"

echo "Iniciando rollback em ${NAMESPACE} usando estratégia ${DEPLOYMENT_TYPE}..."

# Configurar kubectl para o cluster correto
if [[ "${NAMESPACE}" == *"staging"* ]]; then
  aws eks update-kubeconfig --name devops-staging-cluster --region us-east-1
else
  aws eks update-kubeconfig --name devops-production-cluster --region us-east-1
fi

if [ "${DEPLOYMENT_TYPE}" == "blue-green" ]; then
  # Determinar qual deployment está ativo (blue ou green)
  ACTIVE_DEPLOYMENT=$(kubectl get service ${APP_NAME}-service -n ${NAMESPACE} -o jsonpath='{.spec.selector.deployment}')
  
  if [ "${ACTIVE_DEPLOYMENT}" == "blue" ]; then
    PREVIOUS_DEPLOYMENT="green"
  else
    PREVIOUS_DEPLOYMENT="blue"
  fi
  
  echo "Deployment ativo: ${ACTIVE_DEPLOYMENT}"
  echo "Rollback para: ${PREVIOUS_DEPLOYMENT}"
  
  # Verificar se o deployment anterior existe
  if kubectl get deployment ${APP_NAME}-${PREVIOUS_DEPLOYMENT} -n ${NAMESPACE} > /dev/null 2>&1; then
    # Alternar o tráfego de volta para o deployment anterior
    kubectl patch service ${APP_NAME}-service -n ${NAMESPACE} -p "{\"spec\":{\"selector\":{\"deployment\":\"${PREVIOUS_DEPLOYMENT}\"}}}"
    
    echo "Tráfego alternado com sucesso para o ambiente ${PREVIOUS_DEPLOYMENT}!"
  else
    echo "Erro: Deployment anterior (${PREVIOUS_DEPLOYMENT}) não encontrado!"
    exit 1
  fi
  
elif [ "${DEPLOYMENT_TYPE}" == "canary" ]; then
  # Para canary, simplesmente direcionar todo o tráfego de volta para o stable
  echo "Revertendo tráfego para a versão stable..."
  
  # Verificar se o deployment stable existe
  if kubectl get deployment ${APP_NAME}-stable -n ${NAMESPACE} > /dev/null 2>&1; then
    # Restaurar o tráfego para o deployment stable
    kubectl apply -f deploy/kubernetes/${NAMESPACE}/service-stable.yaml -n ${NAMESPACE}
    
    # Remover o deployment canary se existir
    kubectl delete deployment ${APP_NAME}-canary -n ${NAMESPACE} --ignore-not-found=true
    
    echo "Tráfego revertido com sucesso para a versão stable!"
  else
    echo "Erro: Deployment stable não encontrado!"
    exit 1
  fi
  
else
  echo "Erro: Tipo de deployment inválido. Use 'blue-green' ou 'canary'."
  exit 1
fi

# Obter URL da aplicação
INGRESS_HOST=$(kubectl get ingress ${APP_NAME}-ingress -n ${NAMESPACE} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Aplicação disponível em: https://${INGRESS_HOST}"

echo "Rollback concluído com sucesso!"
exit 0
