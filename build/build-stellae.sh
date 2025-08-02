#!/bin/bash
# ==========================================
#    🌟 build-stellae.sh
#    Cria a Stellae Linux do zero
# ==========================================

# Verifica se está como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Execute como root: sudo $0"
    exit 1
fi

# Configurações
ROOTFS="/mnt/stellae-root"
DEBIAN_MIRROR="http://deb.debian.org/debian"

# Cria diretório
mkdir -p $ROOTFS

# Passo 1: Instala o sistema base Debian
debootstrap stable $ROOTFS $DEBIAN_MIRROR

# Passo 2: Monta sistemas necessários
mount -t proc /proc $ROOTFS/proc
mount -t sysfs /sys $ROOTFS/sys
mount -o bind /dev $ROOTFS/dev

# Passo 3: Copia um script de configuração (vem depois)
cp -r config/includes.chroot/* $ROOTFS/

# Passo 4: Entra no sistema e executa a personalização
chroot $ROOTFS /bin/bash -c "bash /stellae-setup.sh"

# Passo 5: Desmonta
umount $ROOTFS/{proc,sys,dev}

echo "✅ Sistema base criado em $ROOTFS"
