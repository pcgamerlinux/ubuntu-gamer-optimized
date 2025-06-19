#!/bin/bash
# =============================================================================
# kde-optimize.sh — Fase 5: Otimizações de desempenho e tearing no KDE Plasma
# Projeto: ubuntu-gamer-optimized | https://github.com/pcgamerlinux/ubuntu-gamer-optimized
# =============================================================================

set -euo pipefail

log()    { echo -e "\e[1;36m[INFO]\e[0m $1"; }
warn()   { echo -e "\e[1;33m[AVISO]\e[0m $1"; }
error()  { echo -e "\e[1;31m[ERRO]\e[0m $1" >&2; exit 1; }

[[ $EUID -ne 0 ]] && error "Este script precisa ser executado como root."

# === TEARING FIX PARA NVIDIA COM X11 ========================================
log "Corrigindo tearing via ForceFullCompositionPipeline..."

mkdir -p /etc/X11/xorg.conf.d
cat <<EOF > /etc/X11/xorg.conf.d/20-nvidia-tearing.conf
Section "Device"
  Identifier "Nvidia Card"
  Driver "nvidia"
  Option "Coolbits" "28"
  Option "TripleBuffer" "True"
  Option "ForceFullCompositionPipeline" "On"
EndSection
EOF

# === COMPOSITOR KDE: DESEMPENHO =============================================
log "Ajustando compositor para desempenho (sem blur, baixa latência)..."

kwriteconfig5 --file kwinrc --group Compositing --key MaxFPS 240
kwriteconfig5 --file kwinrc --group Compositing --key RefreshRate 240
kwriteconfig5 --file kwinrc --group Compositing --key LatencyPolicy "Low"
kwriteconfig5 --file kwinrc --group Compositing --key Backend "OpenGL"
kwriteconfig5 --file kwinrc --group Compositing --key OpenGLIsUnsafe false
kwriteconfig5 --file kwinrc --group Compositing --key ScaleMethod "Smooth"
kwriteconfig5 --file kwinrc --group Compositing --key XRenderSmoothScale true

# Reiniciar KWin (compositor)
qdbus org.kde.KWin /KWin reconfigure || true

# === CPU: ATIVAR PERFORMANCE ================================================
log "Forçando modo de desempenho máximo da CPU..."

echo 'GOVERNOR="performance"' > /etc/default/cpufrequtils
systemctl restart cpufrequtils

# === VALIDAÇÕES =============================================================
log "Validando GPU e ferramentas..."

nvidia-smi || warn "nvidia-smi não respondeu"
gamemoded -s || warn "gamemode não ativo"
mangohud --version || warn "mangohud não instalado corretamente"
vulkaninfo | grep deviceName || warn "vulkaninfo não respondeu corretamente"

log "Fase 5 concluída. Otimizações de desempenho e vídeo aplicadas com sucesso."
log "Reinicie o sistema para aplicar todas as mudanças."
