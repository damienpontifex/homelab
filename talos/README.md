# Talos with cluster api

## Bootstrap
1. Download ISO https://factory.talos.dev
    - Bare metal
    - ARM64 on macOS VM using UTM app, AMD64 for homelab machine
    - Download ISO
1. UTM create linux VM from ISO
    - Networking 
        - Bridged
        - Network card: e1000

## Bootstrap with talosctl
1. `brew install talosctl`
1. Validate nodes and endpoints in [justfile](./justfile)
1. `just apply --insecure`
1. Wait until machine rebooted. Can observe with `just dashboard` (or `just dashboard --insecure` if before apply)
1. `just bootstrap` to setup etcd
1. `just kubeconfig` to update local kubeconfig
1. `just apply-cilium` to setup CNI
1. `just apply-external-secrets` to setup external-secrets
1. `just apply-prometheus-crds` to setup prometheus types

## Nuance on VM on macOS
Need to have macOS be able to route/respond to the packet coming back on the bridge interface. Add the service IP route to send it to VM
```bash
sudo route -n add <lb-ip-pool-address>/24 <utm-vm-ip-address>
# And cleanup after
sudo route -n delete 10.200.10.0/24
```
