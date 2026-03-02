# Tổng quan và cài đặt SaltStack

---

## Mục Lục

- [I. Tổng quan về SaltStack](#i)
  - [1. Các khái niệm cơ bản](#1)
  - [2. Kiến trúc](#2)
- [II. Cài đặt Salt-Master và Salt-Minion](#ii)

---

## I. Tổng quan về SaltStack

### 1. Các khái niệm cơ bản

- SaltStack là một phần mềm mã nguồn mở dùng để quản lý cấu hình và là công cụ để điều kiển từ xa các ứng dụng trên các máy chủ. SaltStack mang tới một hướng tiếp cận mới trong việc quản lý cơ sở hạ tầng trong hệ thống ngày này. Khi sử dụng Salt bạn sẽ dễ dàng quản lý, vận hành và cấu hình hàng ngày máy chủ trong thời gian ngắn.
- SaltStack được viết bằng Python

### 2. Kiến trúc

#### a. Mô hình Hoạt động (Deployment Models)

- SaltStack hoạt động chủ yếu dựa trên hai mô hình chính:
  - Master-Minion: Mô hình tập trung, trong đó máy chủ điều khiển (Master) quản lý và đẩy cấu hình xuống hàng ngàn nút con (Minion).
  - Masterless: Chế độ không cần máy chủ trung tâm. Mỗi node tự chạy lệnh và áp dụng cấu hình cục bộ từ các file được lưu trữ trực tiếp trên máy đó.

#### b. Các thành phần cốt lõi (Core Components)

- Thành phần Điều khiển (The Control Plane)
  - Salt Master: Đóng vai trò là "bộ não" của hệ thống, điều phối mọi hoạt động.
  - Salt Event Bus: Trục xương sống của hệ thống. Mọi thay đổi, phản hồi hoặc yêu cầu đều được coi là một Event chạy trên Bus này.
  - Reactor & Runners: * Reactor: Lắng nghe Event Bus để thực hiện các hành động tự động hóa dựa trên sự kiện (Event-driven automation).
  - Runners: Các module chạy trên Master để thực hiện các tác vụ quản trị (như quản lý job, kiểm tra trạng thái).
  - File Server (/srv/salt): Nơi lưu trữ các tệp trạng thái cấu hình (State files - .sls) dưới định dạng YAML.
  - Pillar Store: Lưu trữ dữ liệu nhạy cảm hoặc dữ liệu cấu hình riêng biệt (như mật khẩu, SSH keys). Dữ liệu này chỉ được gửi tới đúng Minion được chỉ định.
- Thành phần Thực thi (The Data Plane)
  - Salt Minion: Agent chạy trên các máy chủ đích (Web, DB, Cloud Instance).
  - Returner: Thành phần chịu trách nhiệm gửi kết quả thực thi lệnh từ Minion về cho Master hoặc lưu trữ vào DB bên thứ ba.
  - Grains: Hệ thống lưu trữ thông tin tĩnh của Minion (như Hệ điều hành, phiên bản Kernel, CPU, địa chỉ IP). Grains được thu thập khi Minion khởi động.
  - Beacons: Công cụ giám sát cục bộ trên Minion. Nếu có sự kiện bất thường (ví dụ: một file bị sửa đổi, dịch vụ bị stop), Beacon sẽ đẩy sự kiện đó lên Event Bus của Master.

#### c. Cơ chế Truyền tin (Transport Layer)

- SaltStack sử dụng ZeroMQ (0MQ) làm giao thức mặc định, mang lại hiệu năng cực cao và độ trễ thấp.
- Các Port quan trọng
  - Port 4505 (Publisher): Cổng dùng để phát tán (Broadcast) lệnh từ Master xuống tất cả các Minion đồng thời.
  - Port 4506 (Request/Ret): Cổng dùng để Minion gửi phản hồi kết quả về Master, yêu cầu dữ liệu Pillar hoặc thực hiện quá trình trao đổi khóa (Key management).
- Hiểu về ZeroMQ (Message Queue)
  - ZeroMQ là một thư viện nhắn tin bất đồng bộ hiệu năng cao. Trong kiến trúc SaltStack, cơ chế này hoạt động dựa trên các thành phần:
    - Message: Gói tin chứa lệnh (Command) hoặc dữ liệu trạng thái (State).
    - Producer (Master): Thành phần tạo ra lệnh và đẩy vào luồng tin.
    - Consumer (Minion): Thành phần lấy tin nhắn để xử lý.
    - Message Queue: Nơi lưu trữ tạm thời cho đến khi Consumer sẵn sàng nhận tin.
    - Broker: Thành phần trung gian xử lý và quản lý hàng đợi để đảm bảo việc truyền tin giữa Producer và Consumer diễn ra thông suốt.
    - Channel: Cầu nối logic đảm bảo dữ liệu đi đúng hướng giữa các bên tham gia.

#### d. Quy trình Quản lý Cấu hình (Salt States)

- Định nghĩa: Người dùng viết các file .sls (YAML) trong thư mục `/srv/salt` trên Master để mô tả trạng thái mong muốn của hệ thống (ví dụ: Package X phải được cài, Service Y phải đang chạy).
  - Thực thi: Master gửi lệnh state.apply qua port 4505.
  - Thực hiện: Minion nhận lệnh, so sánh trạng thái hiện tại với trạng thái trong file cấu hình.
  - Phản hồi: Minion thực hiện các thay đổi cần thiết và gửi kết quả về Master qua port 4506.

## II. Cài đặt

SaltStack hoạt động với mô hình client-server, trong đó:

- Máy Server: Được cài đặt `salt-master`
- Máy client: Được cài đặt `salt-minion`

---

### Tải Key và tạo Repo

---

```bash
curl -fsSL https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public | tee /etc/apt/keyrings/salt-archive-keyring-2026.pgp

echo "deb [signed-by=/etc/apt/keyrings/salt-archive-keyring-2026.pgp arch=amd64] https://packages.broadcom.com/artifactory/saltproject-deb/ stable main" | sudo tee /etc/apt/sources.list.d/salt.list
```

---

### Cài đặt trên máy Server - máy Master

---

- Đăng nhập với quyền root và thực hiện các lệnh dưới:

```bash
apt install -y salt-master
```

- Các cấu hình quan trọng trong Salt Master trong `/etc/salt/master`
  - Cấu hình mạng cơ bản:
    - `interface: IP`
      - IP mà master sẽ lắng nghe từ minions.
      - Mặc định là 0.0.0.0 (mọi interface)
      - Nên cấu hình với IP của server để giúp chỉ lắng nghe với IP được set
    - `publish_port` (4505) / `ret_port` (4506)
      - Đây là cấu hình Salt Master sẽ mở cổng nào để nhận và gửi lệnh
      - 4505: gửi lệnh tới minions
      - 4506: nhận trả lời từ minions
  - Cấu hình bảo mật và xác thực:
    - `auto_accept`
      - Khi một minions kết nối lần đầu với Master, nó sẽ gửi một public key lên.
      - Nếu auto_accept: False (Mặc định): Master sẽ đưa khóa này vào trạng thái chờ. Chỉ khi đồng ý thì mới có thể giao tiếp. Lệnh xác nhận thủ công: salt-key -a 
      - Nếu auto_accept: True: Master sẽ tự động tin tưởng và chấp nhận mọi Public Key ngay lập tức
    - `rotate_aes_key`
      - Cấu hình này giúp thay đổi aes key giúp tách biệt khi một minion bị chiếm ngăn chặn việc nghe lén sau khi khi tách
  - Cấu hình Cache Job
    - Quản lý lịch sử job đã thực thi (JID và results)
    - `job_cache`: True – Lưu lại kết quả để review
    - `keep_jobs_seconds`: số – Giữ lại kết quả bao nhiêu lâu (Tính theo s)
  - Cấu hình File Server
    - `fileserver_backend`
      - Đây là cấu hình chỉ ra nguồn tài nguyên
        - roots (Mặc định): là nguồn từ các file nằm sẵn trên fs của server
        - gitfs: Là các file nằm trong các nguồn như GitHub hoặc GitLab
    - `file_roots`
      - Là một bản khai báo: Môi trường nào ứng với thư mục nào
    - `pillar_roots`
      - Tương tự như file_roots, đây là nơi bạn khai báo đường dẫn chứa các file .sls của Pillar trên ổ cứng Master.
  - Cấu hình Event & Reactor
    - `reactor`
      - Đây là cơ chế Event-Driven Automation (Tự động hóa dựa trên sự kiện)
  - Cấu hình Cluster
    - `cluster_id` (Tên định danh cụm)
      - Dễ hiểu: Để các Master biết mình thuộc cùng một tổ chức, chúng phải có chung một cái tên.
      - Nếu bạn có nhiều cụm SaltStack khác nhau trong cùng một mạng, cluster_id giúp phân biệt để các Master không kết nối nhầm sang cụm khác.
    - `cluster_peers` (Danh sách thành viên)
      - Dễ hiểu: Bạn liệt kê địa chỉ IP hoặc Hostname của các Master "anh em" vào đây.
      - Tại sao cần: Master 1 cần biết Master 2 và Master 3 đang ở đâu để gửi dữ liệu đồng bộ. Nếu không có danh sách này, Master sẽ đứng cô lập một mình.

---

### Cài đặt trên máy Client - máy Minion

---

- Cài đặt gói `salt-minion`
  ```bash
  apt install -y salt-minion
  ```
- Mở file `/etc/salt/minion` sửa dòng
  ```bash
  master: IP_cua_may_Master
  ```
- Khởi động lại Salt
  ```bash
  systemctl restart salt-minion
  ```

### Thực hiện một số thao tác với SaltStack sau khi cài đặt

#### Xác nhận các máy minion

Đứng trên máy server để thêm vào các private key của các máy minion

```sh
salt-key -L # Liet ke cac public key ma may Master co.
salt-key -A # Them cac key cua may Minion vao trong may Master.
```

Trên màn hình sẽ hiển thị các máy đã kết nối với Master và hỏi xem bạn có tiếp nhận các máy này hay không. Chọn Y để tiếp nhận các key này.