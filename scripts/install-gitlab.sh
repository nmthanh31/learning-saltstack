# =========================================
# 1. YÊU CẦU HỆ THỐNG
# =========================================
# Mở các port: 22 (SSH), 80 (HTTP), 443 (HTTPS)
# Đã cấu hình DNS trỏ về IP server

# =========================================
# 2. BẬT SSH VÀ MỞ FIREWALL
# =========================================

sudo systemctl enable --now ssh

sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable


# =========================================
# 3. CÀI CÁC GÓI CẦN THIẾT
# =========================================

sudo apt update
sudo apt install -y curl


# =========================================
# 4. THÊM GITLAB REPOSITORY (COMMUNITY EDITION)
# =========================================

curl --location "https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh" | sudo bash


# =========================================
# 5. CÀI ĐẶT GITLAB
# =========================================
# Thay https://gitlab.example.com bằng domain của bạn

sudo EXTERNAL_URL="http://10.1.1.141" apt install gitlab-ce


# =========================================
# 6. LẤY MẬT KHẨU ROOT BAN ĐẦU
# =========================================

sudo cat /etc/gitlab/initial_root_password

# Username: root
# Password: (lấy trong file trên)
# Sau khi đăng nhập phải đổi mật khẩu ngay.