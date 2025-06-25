#!/bin/bash
# =============================================================================
# partitioning.sh — Fase 1: Particionamento e montagem com Btrfs (compress=zstd)
# Projeto: ubuntu-gamer-optimized | https://github.com/pcgamerlinux/ubuntu-gamer-optimized
# =============================================================================

set -euo pipefail

# === VARIÁVEIS BASE =========================================================
LOG_FILE="/var/log/ubuntu-gamer-partitioning.log"
exec > >(tee -a "$LOG_FILE") 2>&1

mount_point="/mnt"
DEFAULT_DISK="/dev/nvme0n1"

# === FUNÇÕES UTILITÁRIAS ====================================================
log()    { echo -e "\e[1;36m[INFO]\e[0m $1"; }
warn()   { echo -e "\e[1;33m[AVISO]\e[0m $1"; }
error()  { echo -e "\e[1;31m[ERRO]\e[0m $1" >&2; exit 1; }
confirm(){ read -rp "$(echo -e "\e[1;33m[?]\e[0m $1 [s/N]: ")" resp; [[ "$resp" =~ ^[sS]$ ]]; }

# === PRÉ-VALIDAÇÃO ==========================================================
[[ $EUID -ne 0 ]] && error "Este script deve ser executado como root (sudo)."

ping -c 1 8.8.8.8 &>/dev/null || warn "Sem internet. Isso pode afetar futuras etapas."

[[ -d "$mount_point" ]] || error "Diretório de montagem $mount_point não existe. Verifique sua mídia."

command -v sgdisk >/dev/null || error "sgdisk não encontrado. Instale o pacote 'gdisk'."
command -v mkfs.btrfs >/dev/null || error "mkfs.btrfs não encontrado. Instale o pacote 'btrfs-progs'."

# === DETECÇÃO DO HARDWARE ===================================================
log "Detectando informações do sistema..."

DISK="$(lsblk -ndo NAME,TYPE | grep 'disk' | head -n1 | awk '{print "/dev/" $1}')"
[[ -z "$DISK" ]] && DISK="$DEFAULT_DISK"

[[ ! -b "$DISK" ]] && error "Disco $DISK não encontrado. Verifique o cabo, VM ou altere manualmente no script."

DISK_SIZE_BYTES=$(blockdev --getsize64 "$DISK")
DISK_SIZE_GB=$((DISK_SIZE_BYTES / 1024 / 1024 / 1024))

RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
RAM_GB=$((RAM_KB / 1024 / 1024 + 1))

[[ "$DISK_SIZE_GB" -lt 40 ]] && error "Disco muito pequeno (<40GB). Instalação abortada."

log "Disco detectado: $DISK ($DISK_SIZE_GB GB)"
log "Memória RAM detectada: $RAM_GB GB"

# === CÁLCULOS DE TAMANHOS ===================================================
EFI_SIZE="+512M"

if (( RAM_GB <= 4 )); then
  SWAP_SIZE="+4G"
elif (( RAM_GB <= 8 )); then
  SWAP_SIZE="+8G"
elif (( RAM_GB <= 16 )); then
  SWAP_SIZE="+12G"
else
  SWAP_SIZE="+16G"
fi

ROOT_SIZE="+$((DISK_SIZE_GB / 2))G"  # metade do disco
log "Tamanhos sugeridos:"
echo "  EFI:  $EFI_SIZE"
echo "  Swap: $SWAP_SIZE"
echo "  Root: $ROOT_SIZE"
echo "  Home: espaço restante"

confirm "Deseja continuar com esse particionamento no disco $DISK?" || error "Abortado pelo usuário."

# === PARTICIONAMENTO ========================================================
log "Iniciando particionamento em $DISK..."
sgdisk --zap-all "$DISK"
sgdisk -n 1:0:$EFI_SIZE   -t 1:ef00 -c 1:"EFI System" "$DISK"
sgdisk -n 2:0:$SWAP_SIZE  -t 2:8200 -c 2:"Linux Swap" "$DISK"
sgdisk -n 3:0:$ROOT_SIZE  -t 3:8300 -c 3:"Linux Root" "$DISK"
sgdisk -n 4:0:0           -t 4:8300 -c 4:"Linux Home" "$DISK"
partprobe "$DISK"

# === FORMATAÇÃO E MONTAGEM ==================================================
log "Formatando partições..."
mkfs.vfat -F32 "${DISK}p1"
mkswap "${DISK}p2"
mkfs.btrfs -f -L root "${DISK}p3"
mkfs.btrfs -f -L home "${DISK}p4"

log "Montando ROOT para criar subvolumes..."
mount "${DISK}p3" "$mount_point"
for subvol in @ @home @log @cache @snapshots; do
  btrfs subvolume create "$mount_point/$subvol"
done
umount "$mount_point"

log "Montando subvolumes com compressão zstd:1..."
mount -o noatime,compress=zstd:1,subvol=@ "${DISK}p3" "$mount_point"
mkdir -p "$mount_point"/{home,var/log,var/cache,.snapshots,boot/efi}
mount -o noatime,compress=zstd:1,subvol=@home "${DISK}p3" "$mount_point/home"
mount -o noatime,compress=zstd:1,subvol=@log "${DISK}p3" "$mount_point/var/log"
mount -o noatime,compress=zstd:1,subvol=@cache "${DISK}p3" "$mount_point/var/cache"
mount -o noatime,compress=zstd:1,subvol=@snapshots "${DISK}p3" "$mount_point/.snapshots"
mount "${DISK}p1" "$mount_point/boot/efi"
swapon "${DISK}p2"

# === VALIDAÇÃO FINAL ========================================================
log "Resumo das partições montadas:"
lsblk -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT
echo
df -hT | grep -E '^/dev'
echo
swapon --show

log "Fase 1 concluída com sucesso. Pronto para instalar o sistema base."
