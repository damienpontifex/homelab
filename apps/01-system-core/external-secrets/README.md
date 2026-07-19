# External Secrets cluster bootstrap

## Create app registration
1. Navigate to portal.azure.com
1. Microsoft Entra
1. App registrations
1. New registration
1. name: homelab-external-secrets
1. Copy the Application (client) ID -> `az keyvault secret set --name external-secrets-client-id --vault-name pontifex-homelab --value $(pbpaste)`
1. Manage -> Certificates & secrets -> New client secret -> `az keyvault secret set --name external-secrets-client-secret --vault-name pontifex-homelab --value $(pbpaste)`
1. Navigate to pontifex-homelab Key Vault -> Access policies
1. Create -> Secret permissions (Get) -> Principal as app registration name

```bash
kubectl create namespace external-secrets

function kv-secret() {
  local name=$1
  az keyvault secret show --name $name --vault-name pontifex-homelab --query 'value' --output tsv
}
kubectl create secret generic azure-kv-sp \
  --namespace external-secrets \
  --from-literal ClientID=$(kv-secret external-secrets-client-id) \
  --from-literal ClientSecret=$(kv-secret external-secrets-client-secret)

unset -f kv-secret

until kustomize build --enable-helm . | kubectl apply --server-side=true --filename -; do
  # n.b. cluster secret store resource will fail until pods have started
  sleep 5
done
```

