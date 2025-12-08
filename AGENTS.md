# Homelab GitOps Setup

This repository uses **Kustomize** for manifest management and **ArgoCD** for GitOps deployments.

## Directory Structure

```
apps/
├── base/                          # Shared base manifests (single source of truth)
│   ├── cert-manager/             # Let's Encrypt certificate management
│   ├── prometheus/               # Monitoring and metrics collection
│   └── grafana/                  # Visualization and dashboards
├── local/                        # Local k3d development overrides
│   ├── kustomization.yaml        # Root overlay for local environment
│   ├── cert-manager/
│   ├── prometheus/
│   └── grafana/
└── production/                   # Production environment overrides
    ├── kustomization.yaml        # Root overlay for production
    ├── cert-manager/
    ├── prometheus/
    └── grafana/

argocd/
├── project.yaml                  # ArgoCD AppProject definition
├── local-apps.yaml              # Application for local environment
└── production-apps.yaml         # Application for production environment

k3d/
├── manifests/
│   ├── argocd.yaml              # ArgoCD Helm chart installation
│   └── argocd-application.yaml  # Bootstrap applications for ArgoCD
```

## How It Works

### Kustomize Bases
The `apps/base/` directory contains the base Kubernetes manifests and Helm charts for each application. These are the single source of truth for application definitions.

Each base includes:
- Namespace creation
- Helm chart references with default values
- Default configurations

### Environment Overlays
The `apps/local/` and `apps/production/` directories are Kustomize overlays that reference the bases. They customize the base manifests for their specific environment:

- **Local** (`apps/local/`):
  - Smaller storage requirements (5-10Gi)
  - Shorter retention periods
  - Single replicas for resource efficiency
  - Staging Let's Encrypt certificates

- **Production** (`apps/production/`):
  - Larger storage requirements (50Gi+)
  - Longer retention periods (30+ days)
  - Multiple replicas for high availability
  - Production Let's Encrypt certificates

### ArgoCD Applications
The `argocd/` directory contains Application manifests that tell ArgoCD what to deploy:

- `project.yaml` - Defines the `homelab-project` with source and destination restrictions
- `local-apps.yaml` - Application pointing to `apps/local/` for local development
- `production-apps.yaml` - Application pointing to `apps/production/` for production

When ArgoCD syncs an Application, it uses Kustomize to build the overlay and deploy the resulting manifests.

## Deployment Workflow

### Local Development (k3d)

1. **Bootstrap ArgoCD:**
   ```bash
   make cluster  # Creates k3d cluster with ArgoCD installed
   ```

2. **View Applications:**
   ```bash
   kubectl get applications -n argocd
   ```

3. **Make Changes:**
   - Edit manifests in `apps/base/` or `apps/local/`
   - Commit and push to your repository
   - ArgoCD automatically syncs the changes

4. **Access Services:**
   - ArgoCD: `http://localhost:8080/argocd` (login with admin/password)
   - Grafana: `http://localhost:8080/grafana`
   - Prometheus: `http://localhost:8080/prometheus`

### Production Deployment

1. **Deploy to Production Cluster:**
   ```bash
   kubectl apply -f argocd/project.yaml
   kubectl apply -f argocd/production-apps.yaml -n argocd
   ```

2. **Verify Applications:**
   ```bash
   kubectl get applications -n argocd
   kubectl get ns
   ```

## Customization Guide

### Cert-Manager (Let's Encrypt)

1. **Update Email Address:**
   - Local: Edit `apps/local/cert-manager/patches/email.yaml`
   - Production: Edit `apps/production/cert-manager/patches/email.yaml`

### Prometheus

1. **Storage Requirements:**
   - Local: Modify `apps/local/prometheus/patches/storage.yaml` (default: 5Gi, 7 days retention)
   - Production: Modify `apps/production/prometheus/patches/storage.yaml` (default: 50Gi, 30 days retention)

### Grafana

1. **Admin Password:**
   - Local: Change password in `apps/local/grafana/patches/admin-password.yaml`
   - Production: Use a strong password and consider using Kubernetes secrets

2. **Datasources:**
   - Grafana is configured to automatically connect to Prometheus
   - Default Prometheus URL: `http://kube-prometheus-stack-prometheus.monitoring:9090`

## Best Practices

1. **Never commit secrets** - Use Kubernetes Secrets or external secret managers
2. **Test locally first** - Use k3d to validate changes before pushing to production
3. **Keep bases generic** - Bases should work across all environments
4. **Use overlays for customization** - Only override what differs by environment
5. **Version your dependencies** - Pin Helm chart versions in kustomization files

## Troubleshooting

### Applications Not Syncing

```bash
# Check application status
kubectl describe application homelab-local -n argocd

# View sync logs
kubectl logs -n argocd deployment/argocd-application-controller
```

### Helm Chart Issues

```bash
# Validate kustomize output
kustomize build apps/local

# Check Helm chart availability
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### Storage Issues

```bash
# Check persistent volumes
kubectl get pv
kubectl get pvc -n monitoring

# Check storage class
kubectl get storageclass
```

## Resources

- [Kustomize Documentation](https://kustomize.io/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Cert-Manager Docs](https://cert-manager.io/)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [Grafana Helm Chart](https://grafana.github.io/helm-charts)
