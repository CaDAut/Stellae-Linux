#!/bin/bash
# ==========================================
#    🌟 build-stellae.sh (versão final com limpeza de cache)
#    Gera ISO da Stellae Linux
# ==========================================

set -e

echo "🚀 Iniciando construção da Stellae Linux..."

if [ "$EUID" -ne 0 ]; then
    echo "❌ Execute como root"
    exit 1
fi

cd "$(dirname "$0")/.." || exit 1

# Instalar live-build
echo "🔧 Instalando live-build..."
apt-get update
apt-get install -y live-build squashfs-tools

# LIMPAR TUDO: config e cache
echo "🧹 Limpando configurações antigas e cache..."
rm -rf config/
lb clean --all 2>/dev/null || true

# Configurar live-build com mirrors do Debian
echo "⚙️ Configurando live-build para Debian bookworm"
lb config \
    --binary-images iso-hybrid \
    --architectures amd64 \
    --distribution bookworm \
    --archive-areas "main contrib non-free" \
    --bootloader syslinux \
    --mirror-bootstrap "http://deb.debian.org/debian" \
    --mirror-chroot "http://deb.debian.org/debian" \
    --mirror-chroot-security "http://security.debian.org/debian-security" \
    --mirror-chroot-backports "http://deb.debian.org/debian-backports" \
    --keyring-packages "debian-archive-keyring"

# Forçar repositórios do Debian (evita duplicados)
echo "📝 Forçando repositórios do Debian"
rm -f config/archives/*.list
cat > config/archives/debian.list <<'EOF'
deb http://deb.debian.org/debian bookworm main contrib non-free
deb http://security.debian.org/debian-security bookworm-security main contrib non-free
deb http://deb.debian.org/debian bookworm-updates main contrib non-free
EOF

# Pacotes para XFCE
echo "xfce4" > config/package-lists/xfce.list.chroot
echo "xfce4-goodies" >> config/package-lists/xfce.list.chroot
echo "lightdm" >> config/package-lists/xfce.list.chroot
echo "lightdm-gtk-greeter" >> config/package-lists/xfce.list.chroot
echo "live-boot" >> config/package-lists/xfce.list.chroot
echo "live-config" >> config/package-lists/xfce.list.chroot
echo "live-config-systemd" >> config/package-lists/xfce.list.chroot
echo "sudo" >> config/package-lists/xfce.list.chroot
echo "nano" >> config/package-lists/xfce.list.chroot

# Garantir kernel CORRETO do Debian
echo "VMLINUX: Configurando kernel linux-image-amd64"
lb config --linux-packages "linux-image-amd64"

# Construir a ISO
echo "📦 Construindo a ISO... (30-60 minutos)"
lb build

# Mover para stellae-iso/
mkdir -p stellae-iso
mv binary.iso stellae-iso/ || { echo "❌ Falha: ISO não foi gerada!"; exit 1; }

echo "✅ ISO gerada com sucesso: stellae-iso/binary.iso"
