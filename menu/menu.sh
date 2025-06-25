#!/bin/bash
# =============================================================================
# menu.sh — Menu Interativo com Log e Detecção de Ambiente
# Projeto: ubuntu-gamer-optimized
# =============================================================================

set -euo pipefail

# === CONFIGURAÇÃO INICIAL ===================================================
LOG_FILE="/var/log/ubuntu-gamer-installer.log"
REPO_BASE=$(realpath "$(dirname "$0")/..")
exec > >(tee -a "$LOG_FILE") 2>&1

# === FUNÇÕES COMUNS =========================================================
log()    { echo -e "\e[1;36m[INFO]\e[0m $1"; }
warn()   { echo -e "\e[1;33m[AVISO]\e[0m $1"; }
error()  { echo -e "\e[1;31m[ERRO]\e[0m $1" >&2; exit 1; }
pause()  { read -rp $'\nPressione ENTER para continuar...' _; }

check_script() {
  [[ -f "$1" ]] || error "Script não encontrado: $1"
}

run_phase() {
  local path="$1"
  log "Executando: $path"
  bash "$path"
  log "✅ Concluído: $path"
}

detect_vm() {
  if systemd-detect-virt --vm &>/dev/null; then
    log "Ambiente detectado: VM"
    return 0
  else
    log "Ambiente detectado: Hardware físico"
    return 1
  fi
}

# === CHECAGENS PRÉVIAS ======================================================
[[ $EUID -ne 0 ]] && error "Este script precisa ser executado como root."
ping -c 1 google.com &>/dev/null || warn "Sem internet? Alguns pacotes podem falhar."

# === MENU ===================================================================
while true; do
  clear
  echo -e "\e[1;34mUbuntu Gamer Optimized – Instalação Modular\e[0m"
  echo "======================================================="
  echo "[1] Fase 1 – Particionamento (Btrfs + Subvolumes)"
  echo "[2] Fase 2 – Instalação Base (debootstrap + Kernel)"
  echo "[3] Fase 3 – Pós-instalação (Drivers, Vulkan, CUDA)"
  echo "[4] Fase 4 – KDE Plasma Mínimo (X11)"
  echo "[5] Fase 5 – Otimizações de Vídeo e Desempenho"
  echo "[V] Instalação em VM (modo teste, sem drivers NVIDIA)"
  echo "[A] Executar todas as fases em sequência (modo turbo)"
  echo "[Q] Sair"
  echo "======================================================="
  read -rp "Escolha: " OP

  case "$OP" in
    1) run_phase "$REPO_BASE/fase1-disk-prep/partitioning.sh"; pause ;;
    2) run_phase "$REPO_BASE/fase2-base-install/base-install.sh"; pause ;;
    3) run_phase "$REPO_BASE/fase3-pos-install/pos-install.sh"; pause ;;
    4) run_phase "$REPO_BASE/fase4-kde-install/install-kde.sh"; pause ;;
    5) run_phase "$REPO_BASE/fase5-kde-optimize/kde-optimize.sh"; pause ;;
    [vV])
       detect_vm && run_phase "$REPO_BASE/fase3-pos-install/pos-install-vm.sh" || warn "Você não está em uma VM."
       pause ;;
    [aA])
       for i in 1 2 3 4 5; do
         SCRIPT=$(find "$REPO_BASE/fase${i}-"*/ -name "*.sh" | head -n1)
         check_script "$SCRIPT"
         run_phase "$SCRIPT" || { warn "Erro na Fase $i. Abortando sequência."; break; }
       done
       pause ;;
    [qQ]) echo "Saindo."; break ;;
    *) warn "Opção inválida. Use números de 1 a 5, V, A ou Q." ;;
  esac
done

