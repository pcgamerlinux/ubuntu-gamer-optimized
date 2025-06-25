#!/bin/bash
# =============================================================================
# base-install.sh — Fase 2: Instalação base otimizada do Ubuntu 24.04 LTS
# Projeto: ubuntu-gamer-optimized
# =============================================================================

set -euo pipefail

# === CONFIG ========================================================
LOG_FILE="/var/log/ubuntu-gamer-base-install.log"
exec > >(tee -a "$LOG_FILE") 2>&1

MOUNT_POINT="/mnt"
RELEASE="noble"  # Ubuntu 24.04 LTS codename

# === FUNÇÕES =======================================================
log()    { echo -e "\e[1;36m[INFO]\e[0m $1"; }
warn()   { echo -e "\e[1;33m[AVISO]\e[0m $1"; }
error()  { echo -e "\e[1;31m[ERRO]\e[0m $1" >&2; exit 1; }
confirm(){ read -rp "$(echo -e "\e[1;33m[?]\e[0m $1 [s/N]: ")" resp; [[ "$resp" =~ ^[sS]$ ]]; }

# === VALIDAÇÕES PRÉVIAS ============================================
[[ $EUID -ne 0 ]] && error "Este script deve ser executado como root."

ping -c 1 archive.ubuntu.com &>/dev/null || error "Sem conexão com a internet."

[[ -d "$MOUNT_POINT" ]] || error "Diretório de montagem $MOUNT_POINT não encontrado."

command -v debootstrap >/dev/null || error "Pacote 'debootstrap' ausente. Instale com: sudo apt install debootstrap"

log "Sistema base será instalado em: $MOUNT_POINT"

# === ENTRADA INTERATIVA ============================================
read -rp "Digite o nome do usuário: " USERNAME
read -rp "Digite o nome do computador (hostname): " HOSTNAME
read -rsp "Digite a senha do usuário: " PASSWORD; echo

if [[ ${#PASSWORD} -lt 6 ]]; then
  warn "Senha fraca detectada (menos de 6 caracteres)."
  confirm "Deseja continuar mesmo assim?" || error "Abortado."
fi

# === DEBOOTSTRAP ===================================================
log "Instalando sistema base com debootstrap..."
debootstrap --arch amd64 "$RELEASE" "$MOUNT_POINT" http://archive.ubuntu.com/ubuntu

# === CONFIGURAÇÕES INICIAIS ========================================
log "Configurando hostname e hosts..."
echo "$HOSTNAME" > "$MOUNT_POINT/etc/hostname"

cat <<EOF > "$MOUNT_POINT/etc/hosts"
127.0.0.1   localhost
127.0.1.1   $HOSTNAME
::1         localhost ip6-localhost ip6-loopback
EOF

# === FSTAB COM UUIDs ===============================================
log "Gerando fstab com UUIDs..."
blkid | grep -E '/dev/(nvme|sd)' | awk '{print $1, $3}' | while read -r dev fstype; do
  uuid=$(blkid -s UUID -o value "$dev")
  echo "UUID=$uuid  auto  $fstype  defaults  0  1"
done >> "$MOUNT_POINT/etc/fstab"

# === MONTAGEM PARA CHROOT =========================================
log "Montando diretórios virtuais para chroot..."
for dir in dev proc sys run; do
  mount --bind "/$dir" "$MOUNT_POINT/$dir"
done

# === INSTALAÇÃO INTERNA (CHROOT) ==================================
log "Instalando pacotes essenciais e otimizações..."

chroot "$MOUNT_POINT" /bin/bash -c "
set -e

apt update

# Pacotes base e kernel
apt install -y linux-image-lowlatency linux-headers-lowlatency grub-efi-amd64 \
  btrfs-progs network-manager sudo locales

# Microcode AMD
apt install -y amd64-microcode

# Desempenho
apt install -y cpufrequtils zram-tools earlyoom thermald tuned tuned-utils
systemctl enable --now zramswap.service
systemctl enable --now earlyoom
systemctl enable --now thermald
systemctl enable cpufrequtils

echo 'GOVERNOR=\"performance\"' > /etc/default/cpufrequtils

# PipeWire (sem interface gráfica)
apt install -y pipewire pipewire-pulse pipewire-audio

# Snapper (Btrfs snapshots)
apt install -y snapper
snapper -c root create-config /

# Initramfs com zstd
mkdir -p /etc/initramfs-tools/conf.d
echo 'COMPRESS=zstd' > /etc/initramfs-tools/conf.d/compress.conf
update-initramfs -u

# Tuned profile
systemctl enable tuned
systemctl start tuned

tuned-adm profile latency-performance

# Locales
locale-gen en_US.UTF-8
update-locale LANG=en_US.UTF-8

# Usuário e rede
useradd -m -s /bin/bash $USERNAME
usermod -aG sudo $USERNAME
echo '$USERNAME:$PASSWORD' | chpasswd
systemctl enable NetworkManager

# Fallback de rede
apt install -y ifupdown resolvconf

# Sysctl tuning
cat <<EOT >> /etc/sysctl.conf
vm.swappiness=10
vm.vfs_cache_pressure=50
fs.file-max=2097152
net.core.rmem_max=268435456
net.core.wmem_max=268435456
fs.inotify.max_user_watches=524288
kernel.sched_energy_aware=0
EOT

# Limites para tempo real
cat <<EOF > /etc/security/limits.d/99-realtime.conf
@audio - rtprio 99
@audio - memlock unlimited
@video - rtprio 99
EOF
"

# === INSTALAÇÃO DO GRUB ============================================
log "Instalando GRUB em modo EFI..."
chroot "$MOUNT_POINT" grub-install
chroot "$MOUNT_POINT" update-grub

# === FINAL =========================================================
log "Base do sistema instalada com sucesso com todas as otimizações. Pronto para seguir para a Fase 3 (drivers e interface gráfica)."
