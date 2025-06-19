#!/bin/bash
# =============================================================================
# pos-install.sh — Fase 3: Pós-instalação inicial antes da interface gráfica
# Projeto: ubuntu-gamer-optimized | https://github.com/pcgamerlinux/ubuntu-gamer-optimized
# =============================================================================

set -euo pipefail

# === FUNÇÕES UTILITÁRIAS ====================================================
log()    { echo -e "\e[1;36m[INFO]\e[0m $1"; }
warn()   { echo -e "\e[1;33m[AVISO]\e[0m $1"; }
error()  { echo -e "\e[1;31m[ERRO]\e[0m $1" >&2; exit 1; }

[[ $EUID -ne 0 ]] && error "Este script precisa ser executado como root."
ping -c 1 google.com &>/dev/null || error "Sem conexão com a internet."

# === ATUALIZAÇÃO DO SISTEMA =================================================
log "Atualizando sistema..."
apt update && apt full-upgrade -y

# === KERNEL LOWLATENCY ======================================================
log "Verificando kernel lowlatency..."
apt install -y linux-image-lowlatency linux-headers-lowlatency

# === MICROCODE (AMD/Intel) ==================================================
log "Instalando microcode adequado..."
if grep -qi amd /proc/cpuinfo; then
  apt install -y amd64-microcode
else
  apt install -y intel-microcode
fi

# === DRIVER NVIDIA (APT - LTS) ==============================================
log "Instalando driver NVIDIA 550-server via apt..."
apt install -y nvidia-driver-550-server libnvidia-gl-550-server vdpauinfo nvtop

# === VULKAN + DXVK + VKD3D ==================================================
log "Instalando Vulkan, DXVK e VKD3D..."
apt install -y vulkan-tools libvulkan1 dxvk vkD3D libdxvk* wine

# === CODECS MULTIMÍDIA ======================================================
log "Instalando ubuntu-restricted-extras (codecs, fontes)..."
apt install -y ubuntu-restricted-extras

# === CUDA TOOLKIT ===========================================================
log "Instalando NVIDIA CUDA Toolkit..."
apt install -y nvidia-cuda-toolkit ocl-icd-opencl-dev

# === FFMPEG COM NVENC =======================================================
log "Instalando ffmpeg com suporte NVENC..."
apt install -y ffmpeg libnvidia-encode* libavcodec-extra

# === FLATPAK + FLATHUB ======================================================
log "Instalando Flatpak e adicionando Flathub..."
apt install -y flatpak gnome-software-plugin-flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# === STEAM + GAMEMODE + MANGOHUD ============================================
log "Instalando Steam, Gamemode e MangoHud..."
apt install -y steam gamemode mangohud

# === PERFORMANCE: zRAM + earlyoom + CPUFREQ + THERMALD ======================
log "Ativando zRAM com zram-tools..."
apt install -y zram-tools
systemctl enable --now zramswap.service

log "Instalando earlyoom (proteção contra travamento de RAM)..."
apt install -y earlyoom
systemctl enable --now earlyoom

log "Ativando thermald e cpufrequtils..."
apt install -y thermald cpufrequtils
systemctl enable --now thermald

# === VERIFICAÇÕES FINAIS ====================================================
log "Validações finais:"
uname -r
nvidia-smi || warn "nvidia-smi não respondeu. Verifique driver."
vulkaninfo | grep deviceName || warn "vulkaninfo não respondeu corretamente."
cat /proc/swaps
systemctl status earlyoom | grep Active
