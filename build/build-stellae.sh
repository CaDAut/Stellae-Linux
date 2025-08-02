#!/bin/bash
# ==========================================
#    🌟 build-stellae.sh (versão final e compatível)
#    Funciona no GitHub Actions (Ubuntu 24.04)
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

# Limpar configurações antigas
echo "🧹 Limpando configurações e cache..."
rm -rf config/
lb clean --all || true

# Configuração BÁSICA (sem opções inválidas)
echo "⚙️ Configurando live-build (modo compatível)"
lb config \
    --binary-images iso-hybrid \
    --architectures amd64 \
    --distribution bookworm \
    --archive-areas "main" \
    --bootloader syslinux \
    --mirror-bootstrap "http://deb.debian.org/debian" \
    --mirror-chroot "http://deb.debian.org/debian" \
    --mirror-chroot-security "http://security.debian.org/debian-security"

# Forçar uso de repositórios do Debian (evita conflitos)
echo "📝 Forçando repositórios do Debian"
rm -f config/archives/*.list
cat > config/archives/debian.list <<'EOF'
deb http://deb.debian.org/debian bookworm main
deb http://security.debian.org/debian-security bookworm-security main
deb http://deb.debian.org/debian bookworm-updates main
EOF

# Lista de pacotes mínimos
echo "📝 Definindo pacotes mínimos"
echo "linux-image-amd64" > config/package-lists/kernel.list.chroot
echo "live-boot" >> config/package-lists/kernel.list.chroot
echo "live-config" >> config/package-lists/kernel.list.chroot
echo "live-config-systemd" >> config/package-lists/kernel.list.chroot

echo "xfce4" > config/package-lists/xfce.list.chroot
echo "xfce4-goodies" >> config/package-lists/xfce.list.chroot
echo "lightdm" >> config/package-lists/xfce.list.chroot
echo "sudo" >> config/package-lists/xfce.list.chroot
echo "nano" >> config/package-lists/xfce.list.chroot

# Garantir que o kernel está configurado
lb config --linux-packages "linux-image-amd64"

# Construir a ISO
echo "📦 Construindo a ISO... (30-60 minutos)"
lb build

# Mover para stellae-iso/
mkdir -p stellae-iso
mv binary.iso stellae-iso/ || { echo "❌ Falha: ISO não foi gerada!"; exit 1; }

echo "✅ ISO gerada com sucesso: stellae-iso/binary.iso"
