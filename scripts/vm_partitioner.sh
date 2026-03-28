#!/bin/bash

# Define the target drive
DRIVE="/dev/vda"

echo "Creating GPT partition table on $DRIVE..."
parted -s "$DRIVE" mklabel gpt

echo "Creating partitions..."
# 1. Boot Partition (1GiB)
parted -s "$DRIVE" mkpart "BOOT" fat32 1MiB 1025MiB
parted -s "$DRIVE" set 1 esp on

# 2. Root Partition (11GiB)
parted -s "$DRIVE" mkpart "ROOT" ext4 1025MiB 12289MiB

# 3. Home Partition (Remaining space)
parted -s "$DRIVE" mkpart "HOME" ext4 12289MiB 100%

echo "Formatting filesystems..."
# Adjusting device naming for NVMe (p1, p2) vs SATA (1, 2)
if [[ $DRIVE == *nvme* ]]; then
    P1="${DRIVE}p1"; P2="${DRIVE}p2"; P3="${DRIVE}p3"
else
    P1="${DRIVE}1"; P2="${DRIVE}2"; P3="${DRIVE}3"
fi

mkfs.fat -F 32 "$P1"
mkfs.ext4 "$P2"
mkfs.ext4 "$P3"

echo "Partitioning and formatting complete."
