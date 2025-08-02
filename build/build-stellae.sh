#!/bin/bash
# ==========================================
#    🌟 build-stellae.sh (versão corrigida)
#    Usa live-build para gerar ISO real
# ==========================================

set -e  # Parar se houver erro

echo "🚀 Iniciando construção da Stellae Linux..."

# Verifica root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Execute como root"
    exit 1
fi

# Vai para o diretório do projeto
cd "$(dirname "$0")/.." || exit 1

# Instala live-build (ferramenta oficial do Debian)
echo "🔧 Instalando live-build..."
apt-get update
apt-get install -y live-build squashfs-tools

# Configura o live-build (se ainda não estiver configurado)
if [ ! -d "config" ]; then
    echo "⚙️ Configurando live-build..."
    lb config \
        --binary-images iso-hybrid \
        --architectures amd64 \
        --distribution bookworm \
        --archive-areas "main contrib non-free" \
        --bootloader syslinux \
        --desktop xfce \
        --package-lists "minimal"
fi

# Garante que há algo para instalar
echo "xfce4" > config/package-lists/desktop.list.chroot

# Copia arquivos personalizados (se existirem)
if [ -d "config/includes.chroot" ]; then
    echo "📁 Arquivos personalizados detectados"
fi

# Constrói a ISO
echo "📦 Construindo a ISO... (isso levará 30-60 minutos)"
lb build

# Move para stellae-iso/ para o upload
mkdir -p stellae-iso
mv binary.iso stellae-iso/ || { echo "❌ Falha: ISO não foi gerada!"; exit 1; }

echo "✅ ISO gerada com sucesso: stellae-iso/binary.iso"
