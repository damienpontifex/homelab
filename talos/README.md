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
1. `task talos:bootstrap`

## Nuance on VM on macOS
Need to have macOS be able to route/respond to the packet coming back on the bridge interface. Add the service IP route to send it to VM
```bash
sudo route -n add <lb-ip-pool-address>/24 <utm-vm-ip-address>
# And cleanup after
sudo route -n delete 10.200.10.0/24
```
