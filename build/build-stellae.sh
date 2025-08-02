#!/bin/bash
# ==========================================
#    🌟 build-stellae.sh (versão compatível com Ubuntu)
#    Gera ISO da Stellae com live-build
# ==========================================

set -e

echo "🚀 Iniciando construção da Stellae Linux..."

if [ "$EUID" -ne 0 ]; then
    echo "❌ Execute como root"
    exit 1
fi

cd "$(dirname "$0")/.." || exit 1

# Instalar live-build (se ainda não estiver)
echo "🔧 Instalando live-build..."
apt-get update
apt-get install -y live-build squashfs-tools

# Configuração básica (sem opções inválidas)
if [ ! -d "config" ]; then
    echo "⚙️ Configurando live-build (modo compatível)"
    lb config \
        --binary-images iso-hybrid \
        --architectures amd64 \
        --distribution bookworm \
        --archive-areas "main contrib non-free" \
        --bootloader syslinux
fi

# Forçar uso de pacotes XFCE
echo "xfce4" > config/package-lists/xfce.list.chroot
echo "xfce4-goodies" >> config/package-lists/xfce.list.chroot
echo "lightdm" >> config/package-lists/xfce.list.chroot
echo "lightdm-gtk-greeter" >> config/package-lists/xfce.list.chroot

# Garantir que o sistema saiba que é um live
echo "live" > config/package-lists/live.list.chroot

# Personalizações (se existirem)
if [ -d "config/includes.chroot" ]; then
    echo "📁 Arquivos personalizados serão aplicados"
fi

# Construir a ISO
echo "📦 Construindo a ISO... (30-60 minutos)"
lb build

# Mover para stellae-iso/
mkdir -p stellae-iso
mv binary.iso stellae-iso/ || { echo "❌ Falha: ISO não foi gerada!"; exit 1; }

echo "✅ ISO gerada com sucesso: stellae-iso/binary.iso"
