#!/bin/bash
# ==========================================
#    🌟 build-stellae.sh (versão corrigida)
#    Compatível com GitHub Actions e Ubuntu 24.04
#    Gera ISO da Stellae Linux (Debian Bookworm)
# ==========================================

set -e

echo "🚀 Iniciando construção da Stellae Linux..."

if [ "$EUID" -ne 0 ]; then
    echo "❌ Execute como root"
    exit 1
fi

cd "$(dirname "$0")/.." || exit 1

echo "🔧 Instalando live-build..."
apt-get update
apt-get install -y live-build squashfs-tools

echo "🧹 Limpando configurações e cache antigas..."
rm -rf config/

# Configuração live-build (todas opções de uma vez só, sem duplicidade de repositórios)
echo "⚙️ Configurando live-build para Debian bookworm"
lb config \
    --binary-images iso-hybrid \
    --architectures amd64 \
    --distribution bookworm \
    --archive-areas "main" \
    --bootloader syslinux \
    --mirror-bootstrap "http://deb.debian.org/debian" \
    --mirror-chroot "http://deb.debian.org/debian" \
    --mirror-chroot-security "http://security.debian.org/debian-security" \
    --keyring-packages "debian-archive-keyring" \
    --linux-packages "linux-image-amd64"

# Remover vestígios de Ubuntu (caso tenha sobrado de builds anteriores)
echo "📝 Removendo qualquer vestígio de Ubuntu"
rm -f config/archives/ubuntu.list config/archives/*ubuntu* 2>/dev/null || true

# Lista de pacotes mínimos (apenas pacotes válidos do Debian)
mkdir -p config/package-lists

cat > config/package-lists/kernel.list.chroot <<EOF
linux-image-amd64
live-boot
live-config
live-config-systemd
EOF

cat > config/package-lists/xfce.list.chroot <<EOF
xfce4
xfce4-goodies
lightdm
sudo
nano
EOF

# Construir a ISO
echo "📦 Construindo a ISO... (30-60 minutos)"
lb build

# Procurar pelo arquivo ISO gerado
ISO_FILE=$(ls binary*.iso 2>/dev/null | head -n1)
if [ -z "$ISO_FILE" ]; then
    echo "❌ Falha: ISO não foi gerada!"
    exit 1
fi

mkdir -p stellae-iso
mv "$ISO_FILE" stellae-iso/

echo "✅ ISO gerada com sucesso: stellae-iso/$ISO_FILE"
