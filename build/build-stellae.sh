#!/bin/bash
# ==========================================
#    🌟 build-stellae.sh (otimizado)
#    Mais rápido, mais leve, mais estável
# ==========================================

set -e

echo "🚀 Iniciando construção da Stellae Linux..."

if [ "$EUID" -ne 0 ]; then
    echo "❌ Execute como root"
    exit 1
fi

cd "$(dirname "$0")/.." || exit 1

# Instalar live-build
apt-get update
apt-get install -y live-build squashfs-tools

# Limpar config antiga
rm -rf config/
lb clean --all || true

# Configurar para ser mais leve e rápido
lb config \
    --binary-images iso-hybrid \
    --architectures amd64 \
    --distribution bookworm \
    --archive-areas "main" \
    --bootloader syslinux \
    --mirror-bootstrap "http://deb.debian.org/debian" \
    --mirror-chroot "http://deb.debian.org/debian" \
    --mirror-chroot-security "http://security.debian.org/debian-security" \
    --debootstrap-options="--variant=minbase" \
    --package-lists "minimal"

# Pacotes essenciais XFCE
echo "xfce4" > config/package-lists/xfce.list.chroot
echo "xfce4-goodies" >> config/package-lists/xfce.list.chroot
echo "lightdm" >> config/package-lists/xfce.list.chroot
echo "sudo" >> config/package-lists/xfce.list.chroot
echo "nano" >> config/package-lists/xfce.list.chroot

# Kernel
lb config --linux-packages "linux-image-amd64"

# Construir
echo "📦 Construindo ISO..."
lb build

# Mover para stellae-iso/
mkdir -p stellae-iso
mv binary.iso stellae-iso/ || { echo "❌ Falha: ISO não foi gerada!"; exit 1; }

echo "✅ ISO gerada com sucesso!"
