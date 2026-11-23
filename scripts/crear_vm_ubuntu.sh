#!/usr/bin/env bash
# Crea VMs Ubuntu con instalacion DESATENDIDA (autoinstall/cloud-init por ISO seed).
# Requiere: source scripts/env.sh
set -euo pipefail
make_seed() {
  local name="$1" ip="$2" dir="seed/$name"; mkdir -p "$dir"
  local pubkey; pubkey="$(cat ${SSH_KEY}.pub)"
  cat > "$dir/user-data" <<CLOUD
#cloud-config
autoinstall:
  version: 1
  locale: es_CR.UTF-8
  keyboard: {layout: latam}
  identity:
    hostname: ${name}
    username: ${ADMIN_USER}
    password: "${PW_HASH}"
  ssh:
    install-server: true
    allow-pw: false
    authorized-keys: ["${pubkey}"]
  packages: [qemu-guest-agent, curl, jq, net-tools]
  late-commands:
    - |
      cat > /target/etc/netplan/60-lab.yaml <<NET
      network:
        version: 2
        ethernets:
          enp0s3: {dhcp4: true}
          enp0s8: {dhcp4: no, addresses: [${ip}/24]}
      NET
    - curtin in-target --target=/target -- chmod 600 /etc/netplan/60-lab.yaml
    - curtin in-target --target=/target -- timedatectl set-timezone America/Mexico_City
  user-data: {disable_root: true}
CLOUD
  touch "$dir/meta-data"
  genisoimage -output "$dir/seed.iso" -volid cidata -joliet -rock "$dir/user-data" "$dir/meta-data"
}
create_ubuntu() {
  local name="$1" ip="$2" ram="$3" cpus="$4" disk="$5"
  make_seed "$name" "$ip"
  VBoxManage createvm --name "$name" --ostype Ubuntu_64 --register
  VBoxManage modifyvm "$name" --memory "$ram" --cpus "$cpus" --nic1 nat \
    --nic2 hostonly --hostonlyadapter2 "$VBOX_HOSTONLY" --graphicscontroller vmsvga --vram 16
  VBoxManage createmedium disk --filename "$HOME/VirtualBox VMs/$name/$name.vdi" --size $((disk*1024)) --format VDI
  VBoxManage storagectl "$name" --name SATA --add sata --controller IntelAhci
  VBoxManage storageattach "$name" --storagectl SATA --port 0 --device 0 --type hdd \
    --medium "$HOME/VirtualBox VMs/$name/$name.vdi"
  VBoxManage storageattach "$name" --storagectl SATA --port 1 --device 0 --type dvddrive --medium "$UBUNTU_ISO"
  VBoxManage storageattach "$name" --storagectl SATA --port 2 --device 0 --type dvddrive --medium "seed/$name/seed.iso"
  VBoxManage startvm "$name" --type headless
}
wait_ssh() { until ssh -i "$SSH_KEY" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=5 \
  ${ADMIN_USER}@"$1" 'echo ok' 2>/dev/null; do sleep 10; done; echo "$1 listo"; }

# --- Orquestacion (descomentar para ejecutar) ---
# create_ubuntu tiendacr-web  "$IP_WEB"  3072 2 25
# create_ubuntu tiendacr-siem "$IP_SIEM" 6144 2 50
# wait_ssh "$IP_WEB"; wait_ssh "$IP_SIEM"
