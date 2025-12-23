# Unpoller Deployment

This directory contains the Kubernetes manifests for deploying [Unpoller](https://github.com/unpoller/unpoller) with Azure Key Vault integration using External Secrets Operator.

## Architecture

- **Unpoller**: Collects metrics from UniFi Controller and exposes them to Prometheus
- **Azure Key Vault**: Stores sensitive credentials (UniFi controller password, username, URL)
- **External Secrets Operator**: Syncs secrets from Azure Key Vault to Kubernetes
- **Workload Identity**: Provides secure authentication to Azure Key Vault without storing credentials

## Files

- `namespace.yaml` - Creates the unpoller namespace
- `serviceaccount.yaml` - ServiceAccount with Azure Workload Identity annotations
- `secretstore.yaml` - SecretStore configuration for Azure Key Vault
- `externalsecret.yaml` - ExternalSecret to fetch UniFi credentials from Key Vault
- `kustomization.yaml` - Kustomize configuration with Helm chart and values
- `application.yaml` - ArgoCD Application manifest

## Prerequisites

1. **External Secrets Operator** installed in the cluster
2. **Azure Key Vault** with the following secrets:
   - `unifi-password` - UniFi Controller password
   - `unifi-user` - UniFi Controller username
   - `unifi-url` - UniFi Controller URL (e.g., `https://unifi.home:8443`)

3. **Azure Workload Identity** configured:
   - Managed Identity or App Registration with access to Key Vault
   - Federated credential for the Kubernetes service account

## Configuration

### 1. Update ServiceAccount annotations

Edit `serviceaccount.yaml` and replace the placeholders:

```yaml
annotations:
  azure.workload.identity/client-id: "<AZURE_CLIENT_ID>"
  azure.workload.identity/tenant-id: "<AZURE_TENANT_ID>"
```

### 2. Update SecretStore

Edit `secretstore.yaml` and replace the Key Vault name:

```yaml
spec:
  provider:
    azurekv:
      vaultUrl: "https://<KEYVAULT_NAME>.vault.azure.net"
```

### 3. Configure Azure Key Vault Secrets

Store the following secrets in your Azure Key Vault:

```bash
# Set the UniFi controller credentials
az keyvault secret set --vault-name <KEYVAULT_NAME> --name unifi-password --value "<your-password>"
az keyvault secret set --vault-name <KEYVAULT_NAME> --name unifi-user --value "<your-username>"
az keyvault secret set --vault-name <KEYVAULT_NAME> --name unifi-url --value "https://unifi.home:8443"
```

### 4. Update ArgoCD Application

Edit `application.yaml` and update the Git repository URL:

```yaml
source:
  repoURL: https://github.com/<your-org>/<your-repo>.git
```

## Azure Workload Identity Setup

### Create Managed Identity

```bash
# Create managed identity
az identity create --name unpoller-identity --resource-group <resource-group>

# Get the client ID
IDENTITY_CLIENT_ID=$(az identity show --name unpoller-identity --resource-group <resource-group> --query clientId -o tsv)

# Get the tenant ID
TENANT_ID=$(az account show --query tenantId -o tsv)
```

### Grant Key Vault Access

```bash
# Get the principal ID
IDENTITY_PRINCIPAL_ID=$(az identity show --name unpoller-identity --resource-group <resource-group> --query principalId -o tsv)

# Grant Key Vault access
az keyvault set-policy --name <KEYVAULT_NAME> \
  --secret-permissions get list \
  --object-id $IDENTITY_PRINCIPAL_ID
```

### Create Federated Credential

```bash
# Get your AKS OIDC issuer URL
OIDC_ISSUER=$(az aks show --name <cluster-name> --resource-group <resource-group> --query oidcIssuerProfile.issuerUrl -o tsv)

# Create federated credential
az identity federated-credential create \
  --name unpoller-federated-credential \
  --identity-name unpoller-identity \
  --resource-group <resource-group> \
  --issuer $OIDC_ISSUER \
  --subject system:serviceaccount:unpoller:unpoller
```

## Deployment

### Using ArgoCD

The application will be automatically deployed by ArgoCD:

```bash
kubectl apply -f application.yaml
```

### Manual Deployment with Kustomize

```bash
kubectl apply -k .
```

## Verify Deployment

### Check External Secret Status

```bash
# Check if the secret is synced
kubectl get externalsecret -n unpoller
kubectl describe externalsecret unifi-credentials -n unpoller

# Check if the Kubernetes secret was created
kubectl get secret unifi-credentials -n unpoller
```

### Check Unpoller Pod

```bash
# Check pod status
kubectl get pods -n unpoller

# View logs
kubectl logs -n unpoller -l app.kubernetes.io/name=unpoller

# Check metrics endpoint
kubectl port-forward -n unpoller svc/unpoller 9130:9130
curl http://localhost:9130/metrics
```

## Prometheus Integration

Unpoller exposes metrics on port 9130. To scrape these metrics with Prometheus, add a ServiceMonitor:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: unpoller
  namespace: unpoller
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: unpoller
  endpoints:
    - port: tcp
      interval: 30s
```

## Troubleshooting

### External Secret Not Syncing

```bash
# Check SecretStore status
kubectl get secretstore -n unpoller
kubectl describe secretstore azure-keyvault -n unpoller

# Check External Secrets Operator logs
kubectl logs -n external-secrets-system -l app.kubernetes.io/name=external-secrets
```

### Workload Identity Issues

```bash
# Verify service account annotations
kubectl get sa unpoller -n unpoller -o yaml

# Check pod for identity-related environment variables
kubectl describe pod -n unpoller -l app.kubernetes.io/name=unpoller
```

### Connection to UniFi Controller

```bash
# Check unpoller logs for connection errors
kubectl logs -n unpoller -l app.kubernetes.io/name=unpoller | grep -i error

# Verify the secret values
kubectl get secret unifi-credentials -n unpoller -o yaml
```

## Customization

### Adjust Resources

Edit `kustomization.yaml` to modify resource requests/limits:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### Enable Additional Features

Modify the `upConfig` section in `kustomization.yaml` to enable features like:
- InfluxDB export
- Loki logging
- Debug mode

## References

- [Unpoller Documentation](https://github.com/unpoller/unpoller)
- [External Secrets Operator - Azure Key Vault](https://external-secrets.io/latest/provider/azure-key-vault/)
- [Azure Workload Identity](https://azure.github.io/azure-workload-identity/)
