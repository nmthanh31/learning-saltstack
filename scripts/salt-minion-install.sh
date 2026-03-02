#!/bin/bash

MASTER_IP=10.1.1.136

if [ -z "$MASTER_IP" ]; then
    echo "LỖI: Thiếu IP Master. Ví dụ: sudo ./setup_minion.sh 192.168.1.10"
    exit 1
fi

echo "--- [1/3] Cài đặt Repo SaltStack ---"
apt update && apt install -y curl gnupg lsb-release

mkdir -p /etc/apt/keyrings
curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | \
    gpg --dearmor -o /etc/apt/keyrings/salt-archive-keyring-2026.gpg

echo "deb [signed-by=/etc/apt/keyrings/salt-archive-keyring-2026.gpg arch=amd64] https://packages.broadcom.com/artifactory/saltproject-deb/ stable main" | \
    tee /etc/apt/sources.list.d/salt.list

echo "--- [2/3] Cài đặt Salt Minion ---"
apt update && apt install -y salt-minion

echo "--- [3/3] Cấu hình kết nối về Master ---"
# Tạo file cấu hình riêng để dễ quản lý
echo "master: $MASTER_IP" > /etc/salt/minion.d/master.conf

# Khởi động lại
systemctl enable salt-minion
systemctl restart salt-minion

echo "====================================================="
echo "HOÀN TẤT CÀI ĐẶT SALT MINION"
echo "Đã trỏ về Master: $MASTER_IP"
echo "Vui lòng lên Master chạy 'salt-key -A' để xác nhận."
echo "====================================================="