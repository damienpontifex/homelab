# Talos with cluster api

## Bootstrap
1. Download ISO https://factory.talos.dev
    - Bare metal
    - ARM64 on macOS VM using UTM app
    - Download ISO
1. UTM create linux VM from ISO
    - Networking 
        - Bridged
        - Network card: e1000

## Bootstrap with talhelper
1. `brew install talhelper`
1. Generate schema for YAML intellisense `mkdir -p .schema && talhelper genschema --file .schema/talconfig.json`
1. Edit [./talhelper.yaml](./talhelper.yaml)
1. Edit talenv with control plane ip `sops edit talenv.sops.yaml`
1. `just bootstrap`
1. Eject the virtual disk from the VM

## Nuance on VM on macOS
Need to have macOS be able to route/respond to the packet coming back on the bridge interface. Add the service IP route to send it to VM
```bash
sudo route -n add <lb-ip-pool-address>/24 <utm-vm-ip-address>
# And cleanup after
sudo route -n delete 10.200.10.0/24
```
