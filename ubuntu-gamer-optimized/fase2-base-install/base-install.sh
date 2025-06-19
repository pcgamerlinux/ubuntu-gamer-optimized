#!/bin/bash
# =============================================================================
# base-install.sh — Fase 2: Instalação base do Ubuntu 24.04 via debootstrap
# Projeto: ubuntu-gamer-optimized | https://github.com/pcgamerlinux/ubuntu-gamer-optimized
# =============================================================================

set -euo pipefail

# === CONFIG ========================================================
MOUNT_POINT="/mnt"
RELEASE="noble"  # Ubuntu 24.04 LTS codename

# === FUNÇÕES UTILITÁRIAS ===========================================
log()    { echo -e "\e[1;36m[INFO]\e[0m $1"; }
warn()   { echo -e "\e[1;33m[AVISO]\e[0m $1"; }
error()  { echo -e "\e[1;31m[ERRO]\e[0m $1" >&2; exit 1; }
confirm(){ read -rp "$(echo -e "\e[1;33m[?]\e[0m $1 [s/N]: ")" resp; [[ "$resp" =~ ^[sS]$ ]]; }

# === VERIFICAÇÕES INICIAIS ========================================
[[ $EUID -ne 0 ]] && error "Este script precisa ser executado como root (sudo)."

ping -c 1 archive.ubuntu.com &>/dev/null || error "Sem conexão com a internet."

[[ -d "$MOUNT_POINT" ]] || error "Diretório $MOUNT_POINT não encontrado. Execute o particionamento antes."

log "Iniciando instalação base no ponto de montagem: $MOUNT_POINT"

# === ENTRADA INTERATIVA DE DADOS ==================================
read -rp "Digite o nome do usuário: " USERNAME
read -rp "Digite o nome do computador (hostname): " HOSTNAME
read -rsp "Digite a senha do usuário: " PASSWORD; echo

if [[ ${#PASSWORD} -lt 6 ]]; then
  warn "Senha fraca detectada (menos de 6 caracteres)."
  confirm "Deseja continuar mesmo assim?" || error "Abortado."
fi

# === DEBOOTSTRAP BASE =============================================
log "Instalando sistema base com debootstrap..."
debootstrap --arch amd64 "$RELEASE" "$MOUNT_POINT" http://archive.ubuntu.com/ubuntu

# === CONFIGURAÇÃO INICIAL =========================================
echo "$HOSTNAME" > "$MOUNT_POINT/etc/hostname"

cat <<EOF > "$MOUNT_POINT/etc/hosts"
127.0.0.1   localhost
127.0.1.1   $HOSTNAME
::1         localhost ip6-localhost ip6-loopback
EOF

# === FSTAB ========================================================
log "Gerando fstab..."
blkid | grep -E '/dev/(nvme|sd)' | awk '{print $1, $3, "auto", "defaults", "0", "1"}' | sed 's/"//g' >> "$MOUNT_POINT/etc/fstab"

# === MONTAGEM DO CHROOT ===========================================
log "Montando diretórios do chroot..."
for dir in dev proc sys run; do
  mount --bind "/$dir" "$MOUNT_POINT/$dir"
done

# === INSTALAÇÃO DENTRO DO CHROOT ==================================
log "Entrando no chroot para instalação dos pacotes..."
chroot "$MOUNT_POINT" /bin/bash -c "
set -e
apt update
apt install -y linux-image-lowlatency linux-headers-lowlatency sudo grub-efi-amd64 btrfs-progs network-manager

# Criando usuário
useradd -m -s /bin/bash $USERNAME
echo '$USERNAME:$PASSWORD' | chpasswd
usermod -aG sudo $USERNAME

# Habilitar serviços
systemctl enable NetworkManager
"

# === GRUB E UEFI ==================================================
log "Instalando e configurando GRUB..."
chroot "$MOUNT_POINT" grub-install
chroot "$MOUNT_POINT" update-grub

# === FINAL ========================================================
log "Instalação base finalizada com sucesso!"
log "Você pode agora reiniciar e continuar com a próxima fase."
