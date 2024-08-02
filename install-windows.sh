#!/bin/bash

# wget -qO- https://raw.githubusercontent.com/tonyizdabezt/congenial/main/install-windows.sh | sudo bash

IMAGE_URL="https://dl.lamp.sh/vhd/tiny11_23h2_uefi.xz"

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

apt update && apt install -y util-linux curl wget nano sudo fdisk wget pigz xz-utils

echo ""
echo "    DOWNLOADING WINDOWS IMAGE FILE..."
echo ""

wget -O windows.xz "$IMAGE_URL"

# Check if the download was successful
if [ ! -s windows.xz ]; then
    echo "Error: Failed to download the Windows image file or the file is empty."
    exit 1
fi

# Verify the file type
file_type=$(file -b windows.xz)
if [[ $file_type != *"XZ compressed data"* ]]; then
    echo "Error: The downloaded file is not a valid XZ compressed file."
    echo "File type: $file_type"
    exit 1
fi

# get all block devices, sort by SIZE to get the biggest device
DESTINATION_DEVICE=$(lsblk -x SIZE -o NAME,SIZE | tail -n1 | cut -d ' ' -f 1)

# check if the disk already has multiple partitions
NB_PARTITIONS=$(lsblk | grep -c "$DESTINATION_DEVICE")
if [ "$NB_PARTITIONS" -gt 1 ]; then
    echo "ERROR: Device $DESTINATION_DEVICE already has some partitions."
    echo "Please make sure that $DESTINATION_DEVICE is an empty disk"
    exit 1
fi

echo ""
echo "    COPYING IMAGE FILE... (may take about 5 minutes)"
echo "    Do NOT close this terminal until it finishes"
echo ""

# then, use dd to copy image
echo "Destination device is $DESTINATION_DEVICE"
echo "Running dd command..."
xz -dc ./windows.xz | sudo dd of="/dev/$DESTINATION_DEVICE" bs=4M status=progress

if [ $? -ne 0 ]; then
    echo "Error: Failed to copy the image to the device."
    exit 1
fi

echo ""
echo "    COPY OK"
echo ""

# print the partition table
echo "Partition table:"
fdisk -l

echo ""
echo "    === ALL DONE ==="
echo ""
