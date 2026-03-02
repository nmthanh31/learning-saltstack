#!/bin/bash

set -e

echo "--- [1/5] Cập nhật hệ thống và Repo ---"
apt update && apt install -y curl gnupg lsb-release

# Thêm Key và Repo Broadcom 2026
mkdir -p /etc/apt/keyrings
curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | \
    gpg --dearmor -o /etc/apt/keyrings/salt-archive-keyring-2026.gpg

echo "deb [signed-by=/etc/apt/keyrings/salt-archive-keyring-2026.gpg arch=amd64] https://packages.broadcom.com/artifactory/saltproject-deb/ stable main" | \
    tee /etc/apt/sources.list.d/salt.list

echo "--- [2/5] Cài đặt Salt Master ---"
apt update && apt install -y salt-master

echo "--- [3/5] Cấu hình File Roots & Pillar Roots ---"
# Tạo thư mục vật lý
mkdir -p /srv/salt
mkdir -p /srv/pillar

# Ghi cấu hình vào file riêng biệt trong master.d/
cat <<EOF > /etc/salt/master.d/01_custom.conf
interface: 0.0.0.0
job_cache: True

file_roots:
  base:
    - /srv/salt

pillar_roots:
  base:
    - /srv/pillar
EOF

echo "--- [4/5] Cấu hình Firewall (UFW) ---"
if command -v ufw > /dev/null; then
    ufw allow 4505,4506/tcp
    echo "Đã mở port 4505, 4506"
fi

echo "--- [5/5] Khởi động dịch vụ ---"
systemctl enable salt-master
systemctl restart salt-master

echo "====================================================="
echo "HOÀN TẤT CÀI ĐẶT SALT MASTER"
echo "Thư mục States: /srv/salt"
echo "Thư mục Pillar: /srv/pillar"
echo "====================================================="