#!/bin/bash
# security/setup-waf.sh

set -e

# Definir variáveis
REGION="us-east-2"
WAF_NAME="devops-app-waf"
ALB_ARN="arn:aws:elasticloadbalancing:us-east-2:123456789012:loadbalancer/app/devops-app-alb/abcdef123456"

# Criar Web ACL
WEB_ACL_ID=$(aws wafv2 create-web-acl \
  --name ${WAF_NAME} \
  --scope REGIONAL \
  --default-action Allow={} \
  --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=${WAF_NAME} \
  --region ${REGION} \
  --query "Summary.ARN" \
  --output text )

echo "Web ACL criado: ${WEB_ACL_ID}"

# Adicionar regra de rate limiting
aws wafv2 update-web-acl \
  --name ${WAF_NAME} \
  --scope REGIONAL \
  --id ${WEB_ACL_ID} \
  --default-action Allow={} \
  --rules '[
    {
      "Name": "RateLimitRule",
      "Priority": 1,
      "Statement": {
        "RateBasedStatement": {
          "Limit": 1000,
          "AggregateKeyType": "IP"
        }
      },
      "Action": {
        "Block": {}
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "RateLimitRule"
      }
    },
    {
      "Name": "SQLiRule",
      "Priority": 2,
      "Statement": {
        "ManagedRuleGroupStatement": {
          "VendorName": "AWS",
          "Name": "AWSManagedRulesSQLiRuleSet"
        }
      },
      "OverrideAction": {
        "None": {}
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "SQLiRule"
      }
    },
    {
      "Name": "XSSRule",
      "Priority": 3,
      "Statement": {
        "ManagedRuleGroupStatement": {
          "VendorName": "AWS",
          "Name": "AWSManagedRulesCommonRuleSet",
          "ExcludedRules": [
            {
              "Name": "SizeRestrictions_BODY"
            }
          ]
        }
      },
      "OverrideAction": {
        "None": {}
      },
      "VisibilityConfig": {
        "SampledRequestsEnabled": true,
        "CloudWatchMetricsEnabled": true,
        "MetricName": "XSSRule"
      }
    }
  ]' \
  --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=${WAF_NAME} \
  --region ${REGION}

# Associar Web ACL ao ALB
aws wafv2 associate-web-acl \
  --web-acl-arn ${WEB_ACL_ID} \
  --resource-arn ${ALB_ARN} \
  --region ${REGION}

echo "WAF configurado e associado ao ALB com sucesso!"