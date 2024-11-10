
#!/bin/bash

# Variables
CHART_NAME="castai-node-targetgroup-manager"
CHART_VERSION="0.1.0"
APP_VERSION="1.0"
NAMESPACE="casta-agent"
IMAGE="ronakpatildocker/instacetargetmanager:latest"

# Step 1: Create Helm Chart
helm create $CHART_NAME

# Step 2: Remove Unnecessary Files
rm $CHART_NAME/templates/hpa.yaml
rm $CHART_NAME/templates/ingress.yaml
rm $CHART_NAME/templates/service.yaml
rm -rf $CHART_NAME/templates/tests

# Step 3: Update Chart.yaml
cat <<EOF > $CHART_NAME/Chart.yaml
apiVersion: v2
name: $CHART_NAME
description: A Helm chart for deploying Castai agent resources
version: $CHART_VERSION
appVersion: "$APP_VERSION"
EOF

# Step 4: Update values.yaml
cat <<EOF > $CHART_NAME/values.yaml
namespace: $NAMESPACE
replicas: 2
image: "$IMAGE"

# Environment variables for the deployment
awsRegion: "us-west-2"  # Default AWS region, can be overridden
apiKey: "replace-with-your-base64-api-key"
clusterId: "replace-with-your-base64-cluster-id"

# Node selector for scheduling
nodeSelector: {}

# Tolerations for scheduling
tolerations: []
EOF

# Step 5: Create ServiceAccount Template
cat <<EOF > $CHART_NAME/templates/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: target-registrar-sa
  namespace: {{ .Values.namespace }}
EOF

# Step 6: Create ClusterRole Template
cat <<EOF > $CHART_NAME/templates/clusterrole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: target-registrar-role
rules:
  - apiGroups: [""]
    resources: ["pods", "services", "endpoints", "configmaps"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get"]
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["metrics.k8s.io"]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
EOF

# Step 7: Create ClusterRoleBinding Template
cat <<EOF > $CHART_NAME/templates/clusterrolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: target-registrar-role-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: target-registrar-role
subjects:
  - kind: ServiceAccount
    name: target-registrar-sa
    namespace: {{ .Values.namespace }}
EOF

# Step 8: Create Secret Template
cat <<EOF > $CHART_NAME/templates/secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: castai-secrets
  namespace: {{ .Values.namespace }}
type: Opaque
data:
  apiKey: {{ .Values.apiKey | b64enc }}
  clusterId: {{ .Values.clusterId | b64enc }}
EOF

# Step 9: Create Deployment Template
cat <<EOF > $CHART_NAME/templates/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: castai-deployment
  namespace: {{ .Values.namespace }}
  labels:
    app: castai-app
spec:
  replicas: {{ .Values.replicas }}
  selector:
    matchLabels:
      app: castai-app
  template:
    metadata:
      labels:
        app: castai-app
    spec:
      serviceAccountName: target-registrar-sa
      containers:
      - name: castai-container
        image: {{ .Values.image }}
        ports:
        - containerPort: 8080
        env:
        - name: AWS_REGION
          value: {{ .Values.awsRegion | quote }}
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: castai-secrets
              key: apiKey
        - name: CLUSTER_ID
          valueFrom:
            secretKeyRef:
              name: castai-secrets
              key: clusterId
      nodeSelector:
{{ toYaml .Values.nodeSelector | indent 8 }}
      tolerations:
{{ toYaml .Values.tolerations | indent 8 }}
EOF

# Step 10: Package the Helm Chart
helm package $CHART_NAME

echo "Helm chart $CHART_NAME has been created and packaged successfully."
echo "Next steps:"
echo "1. Upload $CHART_NAME-$CHART_VERSION.tgz to your GitHub repository under the 'charts' directory."
echo "2. (Optional) Set up GitHub Pages to host your Helm chart repository."
echo "3. Users can then add your Helm repo and install the chart using the provided commands."