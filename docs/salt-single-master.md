# Cấu hình Salt Stack với mô hình Single Master

---

## Mục lục

- [I. Mô hình kiến trúc](#i)
  - [1. Thành phần chính](#1)
  - [2. Mô hình](#2)
  - [3. Luồng hoạt động](#3)
  - [4. Các đặc điểm cần biết](#4)
- [II. Cầu hình thực tế](#i)

---

## I. Mô hình hệ thống

---

### 1. Thành phần chính

Mô hình Single Master dựa trên sự phối hợp giữa 1 máy chủ điều khiển trung tâm và các node mục tiêu:

- Salt Master (Trung tâm điều khiển - Server Master)
  - Lưu trữ các tệp trạng thái (State - SLS), dữ liệu cấu hình (Pillar) và hệ thống tệp (File server)
  - Quản lý khóa (Key Management) để xác thực các Minion
  - Phát tán lệnh và điều phối quá trình thực thi toàn hệ thống
- Salt Minion (Máy Client)
  - Là Agent chạy trên từng server mục tiêu
  - Duy trì kết nối liên tục để nhận lệnh từ Master
  - Thực thi các tệp trạng thái và gửi kết quả báo cáo về Master

### 2. Mô hình

Single-Master-Architecture

### 3. Luồng hoạt động

Quy trình vận hành một hệ thống Single Master SaltStack diễn ra qua các bước sau:

1. Handshake: Minion khởi động, tạo cặp RSA key và gửi Public key lên Master để yêu cầu giao tiếp
2. Authentication: Admin kiểm tra và chấp nhận (accept) key của Minion
3. Trigger: Admin thực thi câu lệnh áp dụng
4. Master Processing: Master thực hiện biên dịch (Compile) các tệp trạng thái (SLS + Pillar + template Jinja) thành dữ liệu thực thi riêng từng Minion
5. Distribution: Master gửi gói công việc xuống Minion thông qua giao thức ZeroMQ
6. Minion Execution:
  - Nhận và giải mã Job
  - So sánh trạng thái mong muốn (Desired State) với trạng thái thực tế
  - Thực hiện hành động thay đổi nếu phát hiện sai lệnh (Drift)
7. Reporting: Minion trả kết quả thực thi về cho Master để tổng hợp báo cáo

Cơ chế giao tiếp quan trọng:

- Giao tiếp mặc định: Sử dụng Port 4505 (Publisher - phát tán tin) và Port 4506 (Request/Ret - nhận phản hồi/quản lý key).
- Mô hình: Pull-based event-driven agent model (Các Agent chủ động lắng nghe sự kiện từ Master).

### 4. Các đặc điểm cần biết

Tính idempotency

- Một State chỉ thực sự gây ra thay đổi trên hệ thống khi - Hệ thống chưa đạt đến trạng thái được định nghĩa. - Có sự thay đổi cấu hình ngoài ý muốn - Ý nghĩa: Việc chạy lại một lệnh nhiều lần trên hệ thống đã chuẩn sẽ không phát sinh thêm bất cứ thay đổi nào giúp hạ tầng luôn ổn định  
Desired State Model
- Salt tập trung vào kết quả cuối cùng thay vì các bước thực hiện thủ công - Salt không quan tâm hệ điều hành sẽ dùng lệnh gì (apt/yum), nó chỉ đảm bảo mục tiêu: "Phần mềm Nginx phải tồn tại trên hệ thống"  
Key Management (Quản lý Khóa)
- Mỗi Minion sử dụng một cặp khóa RSA để mã hóa đường truyền.
- Master lưu trữ các khóa đã chấp nhận tại: /etc/salt/pki/master/.
- Rủi ro bảo mật: Nếu máy chủ Master bị xâm nhập (compromised), toàn bộ hạ tầng bên dưới sẽ bị kiểm soát. Do đó, việc quản lý và phê duyệt key cần được thực hiện chặt chẽ.

## II. Cấu hình thực tế

---

### Bài toán đặt ra

Cấu hình mô hình Single Master trong SaltStack được dùng để giải quyết bài toán:

- Quản lý cấu hình NGINX tập trung từ một Master.
- Đảm bảo Desired State (cài đặt, service, cấu hình luôn đúng chuẩn).
- Ngăn chặn Configuration Drift khi có thay đổi thủ công.
- Tự động hóa hoàn toàn việc:
  - Cài package
  - Quản lý service
  - Quản lý file cấu hình
  - Quản lý Virtual Host
- Hỗ trợ cấu hình động theo môi trường (dev/prod) bằng Pillar.
- Có khả năng thêm Minion mới và áp dụng state mà không cần cấu hình lại thủ công.

### Thực hiện cấu hình

## Bài thực hành này sử dụng Ubuntu cho 2 VM với 2 IP 10.1.1.136 10.1.1.132

#### Bước 1: Cài đặt Salt Master và Salt Minion ([tại đây](/docs/salt-install.md))

- Thêm cấu hình trong Salt Master
  - Chỉnh sửa cấu hình trong file `/etc/salt/master`
  ```bash
  interface: 0.0.0.0
  auto_accept: False
  worker_threads: 5
  file_roots:
      base:
          - /srv/salt # Thư mục làm việc chính lưu các State
  pillar_roots:
      base:
          - /srv/pillar # Thư mục lưu các file bảo mật quan trọng
  ```
  - Tạo thư mục làm việc
  ```bash
  sudo mkdir -p /srv/salt/nginx/files
  sudo mkdir -p /srv/pillar
  ```
- Thêm cấu hình trong Salt Minion
  - Chỉnh sửa cấu hình trong file `/etc/salt/minion`
  ```bash
  master: <IP_MASTER>
  id: web01
  ```

#### Bước 2: Quản lý cài đặt và Service NGINX

- Tạo file `/srv/salt/nginx/init.sls` viết bằng jinja (Cách viết jinja [tại đây](/docs/jinja-overview.md))
  ```bash
  nginx: #ID
    pkg.installed: []

    service.running:
      - enable: True
      - require:
        - pkg: nginx
  ```
- Áp dụng với câu lệnh `salt`
  ```bash
  salt '*' state.apply nginx # * là id của minion (* là tất cả) nginx là id trong file State
  ```
  ![kết quả](/imgs/apply-salt.png)
- Kiểm tra trạng thái trên máy Minion:
  ```bash
  systemctl status nginx.service
  ```

#### Bước 3: Quản lý file cấu hình

- Ở bước này ta thử quản lý file cấu hình của Nginx bằng file State
- Tạo file cấu hình mẫu trong `/srv/salt/nginx/files/index.html`
  ```bash
  <!DOCTYPE html>
  <html>
  <head>
      <title>Welcome to Nginx via SaltStack</title>
  </head>
  <body>
      <h1>Hello</h1>
      <p>This page is managed by SaltStack with default domain.</p>
  </body>
  </html>
  ```
- Chỉnh sửa file `init.sls`
  ```bash
  /etc/nginx/nginx.conf:       # Đích đến (Path trên Minion)
    file.managed:              # Function: Đảm bảo file tồn tại và đúng nội dung
      - source: salt://nginx/files/nginx.conf  # Nguồn: File gốc nằm trên Salt Master
      - user: root             # Chủ sở hữu file trên Minion
      - group: root            # Nhóm sở hữu
      - mode: 644              # Quyền hạn (Read cho mọi người, Write cho owner)
  /var/www/html/index.html:
    file.managed:
      - source: salt://nginx/files/index.html
      - user: www-data
      - group: www-data
      - mode: 644
      - makedirs: True         # (7) Create Directory
  nginx:
    service.running:           # Đảm bảo service Nginx luôn chạy
      - enable: True           # Start on Boot
      - reload: True           # Khi có thay đổi, dùng lệnh 'reload' thay vì 'restart' (tránh downtime)
      - watch:                 # Cơ chế giám sát
        - file: /etc/nginx/nginx.conf # Nếu file này thay đổi, thực hiện reload service ngay lập tức
  ```
- Apply: `salt '*' state.apply nginx`

#### Bước 4: Quản lý Virtual Host

- Ở bước này, tôi sẽ tạo một web mới với domain là vhost1 với virtual host
- Tạo file web html cho vhost1 trong `/srv/salt/nginx/files/vhost1.index`
  ```bash
  <!DOCTYPE html>
  <html>
  <head>
      <title>Welcome to Nginx via SaltStack</title>
  </head>
  <body>
      <h1>Hello</h1>
      <p>This page is managed by SaltStack with vhost1 domain.</p>
  </body>
  </html>
  ```
- Tạo file virtual host cho vhost1 trong `/srv/salt/nginx/files/vhost1.conf`
  ```bash
  server {
    listen 80;
    server_name vhost1.com www.vhost1.com;
    root /var/www/html/;
    index vhost1.index
  }
  ```
- Viết file State cấu hình trên Minion `init.sls`
  ```bash
  # 1. Quản lý file cấu hình tổng (Main Config)
  /etc/nginx/nginx.conf:
    file.managed:
      - source: salt://nginx/files/nginx.conf
      - user: root
      - group: root
      - mode: 644
  /var/www/html/index.html:
  file.managed:
    - source: salt://nginx/files/index.html
    - user: www-data
    - group: www-data
    - mode: 644
    - makedirs: True

  # 2. Quản lý file nội dung HTML cho vhost1
  /var/www/html/vhost1.index:
    file.managed:
      - source: salt://nginx/files/vhost1.index
      - user: www-data
      - group: www-data
      - mode: 644
      - makedirs: True

  # 3. Quản lý file cấu hình Virtual Host (vhost1)
  /etc/nginx/sites-available/vhost1.conf:
    file.managed:
      - source: salt://nginx/files/vhost1.conf
      - user: root
      - group: root
      - mode: 644

  # 4. Kích hoạt Virtual Host bằng cách tạo Symlink
  /etc/nginx/sites-enabled/vhost1.conf:
    file.symlink:
      - target: /etc/nginx/sites-available/vhost1.conf
      - force: True  # Ghi đè nếu đã có file/link cũ trùng tên

  # 5. Quản lý Service Nginx
  nginx:
    service.running:
      - enable: True
      - reload: True
      - watch:
        - file: /etc/nginx/nginx.conf
        - file: /etc/nginx/sites-available/vhost1.conf # Reload khi thay đổi cấu hình vhost
  ```

- Apply: `salt '*' state.apply nginx`
- Kết quả
  - Khi truy cập domain mặc định
  ![kq1](/imgs/salt-vh-1-nginx.png)
  - Khi truy cập với domain vhost1
  ![kq2](/imgs/salt-vh-2-nginx.png)

#### Bước 5: Quản lý Pillar
- Tạo file dữ liệu `/srv/pillar/nginx.sls`
  ```bash
  nginx_port: 80              # (1) Biến số cổng
  vhost_domain: vhost1.com  # (2) Biến tên miền
  vhost_root: /var/www/html # (3) Biến đường dẫn thư mục web
  ``` 
- Tạo file phần quyền `/srv/pillar/top.sls`
  ```bash
  base:                  # Môi trường mặc định
    'web01':             # Đối tượng nhận (Targeting)
      - nginx            # File Pillar sẽ được gán (nginx.sls)
  ```
- Sửa file conf của vhost1 `/srv/salt/nginx/files/vhost1.conf`
  ```bash
  server {
    listen {{ pillar['nginx_port'] }};
    server_name {{ pillar['vhost_domain'] }};
    root {{ pillar['vhost_root'] }};
    index vhost1.html;
  }
  ```

- sửa file `init.sls`
  ```bash
  /etc/nginx/sites-available/vhost1.conf:
    file.managed:
      - source: salt://nginx/files/vhost1.conf
      - user: root
      - group: root
      - mode: 644
      - template: jinja
  ```
- Các lệnh:
  - `salt '*' saltutil.refresh_pillar`: Lệnh này ép Minion xóa cache cũ và tải lại Pillar mới từ Master
  - `salt 'web01' pillar.item nginx_port`: Lệnh kiểm tra theo biến