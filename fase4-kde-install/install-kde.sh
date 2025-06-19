#!/bin/bash
# =============================================================================
# install-kde.sh — Fase 4: Instalação do KDE Plasma mínimo
# Projeto: ubuntu-gamer-optimized | https://github.com/pcgamerlinux/ubuntu-gamer-optimized
# =============================================================================

set -euo pipefail

# === FUNÇÕES ================================================================
log()    { echo -e "\e[1;36m[INFO]\e[0m $1"; }
warn()   { echo -e "\e[1;33m[AVISO]\e[0m $1"; }
error()  { echo -e "\e[1;31m[ERRO]\e[0m $1" >&2; exit 1; }

[[ $EUID -ne 0 ]] && error "Este script precisa ser executado como root."

# === KDE MINIMAL ============================================================
log "Instalando KDE Plasma mínimo..."
apt update
apt install -y --no-install-recommends \
  kde-plasma-desktop \
  sddm \
  plasma-discover-backend-flatpak \
  dolphin konsole kate

# === DEFINIR SDDM COMO PADRÃO ==============================================
log "Configurando SDDM como gerenciador de login padrão..."
echo "/usr/bin/sddm" > /etc/X11/default-display-manager
systemctl enable sddm

# === GARANTIR X11 (não usar Wayland com NVIDIA) ============================
log "Forçando X11 no SDDM para compatibilidade com NVIDIA..."
mkdir -p /etc/sddm.conf.d
cat <<EOF > /etc/sddm.conf.d/kde-x11.conf
[General]
DisplayServer=x11
EOF

# === FLATPAK E DISCOVER GUI ================================================
log "Instalando suporte gráfico ao Flatpak com Discover..."
apt install -y plasma-discover flatpak

# === VALIDAÇÕES ============================================================
log "Validações rápidas:"
command -v startplasma-x11 && echo "✔️ KDE instalado com sucesso"
test -f /etc/sddm.conf.d/kde-x11.conf && echo "✔️ X11 forçado com sucesso"

log "Fase 4 concluída. Você pode reiniciar e logar no KDE Plasma (X11)."
