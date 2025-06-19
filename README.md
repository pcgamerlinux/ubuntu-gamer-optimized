# 🎮 Ubuntu Gamer Optimized – Sobrevivendo à Tecnologia

Este repositório faz parte da série **"Sobrevivendo à Tecnologia"** do canal [PcGamerLinux no YouTube](https://www.youtube.com/@PcGamerLinux) — um projeto que usa o poder do Linux para dar sobrevida a PCs e notebooks antigos, transformando-os em máquinas capazes de **editar vídeos, jogar com qualidade e produzir conteúdo**.

💡 Nosso foco é **ensinar gratuitamente** como instalar, configurar e otimizar o **Ubuntu 24.04 LTS** para:

- 🧠 Alta performance mesmo em hardware mais modesto
- 🎮 Jogos via Steam, Proton, Vulkan, DXVK e MangoHud
- 🎥 Edição de vídeo com suporte a NVENC, DaVinci Resolve, FFmpeg, OBS Studio
- 🧩 Criação de sistemas personalizados com zRAM, Btrfs, compressão zstd, Flatpak e KDE Plasma

---

## 🔧 Sobre o Projeto

Este repositório contém uma instalação modular do Ubuntu Gamer Otimizado, com scripts em Shell prontos para uso via Live USB ou ISO personalizada.

📦 **Recursos principais:**

- Kernel `lowlatency` para resposta imediata
- Drivers NVIDIA 550 LTS integrados
- Suporte a Vulkan, Gamemode, CUDA e FFmpeg com NVENC
- Desktop KDE com configurações finas para creators e gamers
- Instalação passo a passo via `menu.sh`

---

## 🧪 Assista à série completa

🎬 Vídeo de apresentação da série:  
[https://www.youtube.com/watch?v=pS7fkwzC2Qw&t=474s](https://www.youtube.com/watch?v=pS7fkwzC2Qw&t=474s)

---

## 🌐 Comunidade

Junte-se à nossa comunidade no Reddit:  
👉 [`/r/pcgamerlinux`](https://reddit.com/r/pcgamerlinux)

---

## 💻 Sobre o Canal

[PcGamerLinux](https://www.youtube.com/@PcGamerLinux) é um canal brasileiro que mostra como você pode transformar seu PC com Linux em uma estação de jogos, trabalho e criatividade — **sem depender do Windows**.

> Tutoriais, dicas, benchmarks e liberdade para criadores de conteúdo e entusiastas do open source.

---

## 📜 Licença

MIT – uso livre e educacional.  



# 🎮 Ubuntu Gamer Optimized

Instalação modular e otimizada do **Ubuntu 24.04 LTS** com foco em:
- 🧠 Baixa latência
- 🎮 Alto desempenho em jogos (Proton, Steam, DXVK, Vulkan)
- 🖥️ Produção de conteúdo (OBS Studio, DaVinci Resolve, NVENC, CUDA)
- 🎨 KDE Plasma com otimizações visuais
- 🧪 Scripts profissionais testados em hardware real (NVIDIA RTX 2060 Super + Ryzen 5 3600)

---

## 🚀 Instalação Rápida (Live USB com Git)

```bash
git clone https://github.com/pcgamerlinux/ubuntu-gamer-optimized.git
cd ubuntu-gamer-optimized/menu
chmod +x menu.sh
sudo ./menu.sh
