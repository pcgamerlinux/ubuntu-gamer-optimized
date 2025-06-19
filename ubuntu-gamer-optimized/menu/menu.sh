#!/bin/bash
# =============================================================================
# menu.sh — Menu Interativo para instalação Ubuntu Gamer Otimizado
# Projeto: https://github.com/pcgamerlinux/ubuntu-gamer-optimized
# =============================================================================

set -euo pipefail

# === FUNÇÕES UTILITÁRIAS =====================================================
log()    { echo -e "\e[1;36m[INFO]\e[0m $1"; }
warn()   { echo -e "\e[1;33m[AVISO]\e[0m $1"; }
error()  { echo -e "\e[1;31m[ERRO]\e[0m $1" >&2; exit 1; }

[[ $EUID -ne 0 ]] && error "Este script precisa ser executado como root."

# === VERIFICAÇÕES PRELIMINARES ==============================================
REPO_BASE=$(realpath "$(dirname "$0")/..")
[[ ! -d "$REPO_BASE/fase1-disk-prep" ]] && error "Repositório incompleto. Clonou tudo corretamente?"

ping -c 1 google.com &>/dev/null || warn "Sem internet? Alguns scripts exigem conexão."

# === MENU ====================================================================
while true; do
  clear
  echo -e "\e[1;34mUbuntu Gamer Optimized - Instalação Modular\e[0m"
  echo "======================================================="
  echo "Escolha uma fase para executar:"
  echo "  [1] Fase 1 – Particionamento do Disco"
  echo "  [2] Fase 2 – Instalação do Sistema Base"
  echo "  [3] Fase 3 – Pós-instalação (Drivers, CUDA, Vulkan)"
  echo "  [4] Fase 4 – Instalar KDE Plasma"
  echo "  [5] Fase 5 – Otimizações do KDE"
  echo "  [A] Executar todas as fases em sequência (modo turbo)"
  echo "  [Q] Sair"
  echo "======================================================="
  read -rp "Escolha: " OP

  case "$OP" in
    1) bash "$REPO_BASE/fase1-disk-prep/partitioning.sh" ;;
    2) bash "$REPO_BASE/fase2-base-install/base-install.sh" ;;
    3) bash "$REPO_BASE/fase3-pos-install/pos-install.sh" ;;
    4) bash "$REPO_BASE/fase4-kde-install/install-kde.sh" ;;
    5) bash "$REPO_BASE/fase5-kde-optimize/kde-optimize.sh" ;;
    [aA])
       for i in 1 2 3 4 5; do
         echo -e "\n\n>> Executando Fase $i..."
         bash "$REPO_BASE/fase${i}-*/"*.sh || { warn "Erro na Fase $i. Abortando sequência."; break; }
       done
       ;;
    [qQ]) echo "Saindo."; break ;;
    *) warn "Opção inválida. Use números de 1 a 5, A ou Q." ;;
  esac

  echo -e "\nPressione ENTER para voltar ao menu..."
  read
done
