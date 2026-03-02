# Cấu hình Salt Stack với mô hình Multiple Master

---

## Mục lục

- [I. Mô hình kiến trúc](#i)
  - [1. Thành phần chính](#1)
  - [2. Mô hình triển khai và Chế độ hoạt động](#2)
  - [3. Luồng hoạt động](#3)
  - [4. Các đặc điểm cần biết](#4)
- [II. Cầu hình thực tế](#i)

---

## I. Mô hình kiến trúc

---

### 1. Thành phần chính

Mô hình Multi-Master là giải pháp mở rộng quy mô, loại bỏ điểm yếu SPoF bằng cách triển khai hai hay nhiều máy chủ điều khiển trung tâm

- Cụm Salt Master (Multi-Node):
  - Tập hợp các máy chủ có vai trò tương đương
  - Lưu trữ tập trung các State Files (`/srv/salt`), Pillar Data(`/srv/pillar`)
  - Mỗi Master giữ một bản sao của PKI (Public Key Infrastructure) để xác thực Minion
  - Phân phối gánh nặng tính toán khi hệ thống có quá nhiều Minion
- Salt Minion
  - Agent được cấu hình để nhận nhiều Master
  - Duy trì các phiên kết nối ZeroMQ song song đến toàn bộ danh sách Master.
  - Có khả năng tự chuyển đổi hoặc nhận lệnh đồng thời tùy theo cấu hình `master_type`

---

### 2. Mô hình triển khai và Chế độ hoạt động

Trong kiến trúc Multi-Master, quản trị viên có thể lựa chọn các phương thức vận hành khác nhau tùy thuộc vào yêu cầu về tính sẵn sàng và hiệu suất của hệ thống.

#### A. Chế độ Failover

- Đây là mô hình Active_Passive cơ bản. Ở chế độ này, Minion sẽ ưu tiên kết nối với Master đầu tiên được liệt kê trong danh sách cấu hình. Nó chỉ thực hiện chuyển đổi (failover) sang Master tiếp theo nếu phát hiện Master chính bị mất kết nối hoặc không phản hồi. Ưu điểm của mô hình này là sự đơn giản trong việc quản lý mã định danh công việc (Job ID), tuy nhiên nhược điểm lớn nhất là luôn tồn tại một khoảng thời gian chờ (timeout) nhất định trong quá trình chuyển đổi dịch vụ khi có sự cố xảy ra.

#### B. Chế độ Distributed

- Đây là mô hình Active-Active, nơi tất cả các Master trong cụm đều ở trạng thái sẵn sàng phục vụ. Minion sẽ thiết lập kết nối đồng thời và lắng nghe lệnh từ tất cả các Master cùng một lúc. Khi một Master bất kỳ trong cụm phát lệnh, Minion sẽ thực thi ngay lập tức mà không có độ trễ chuyển đổi. Mô hình này giúp tận dụng tối đa tài nguyên phần cứng và đảm bảo tính sẵn sàng cao nhất cho hệ thống. Tuy nhiên, nó đòi hỏi một quy trình đồng bộ hóa dữ liệu (State, Pillar, PKI) cực kỳ khắt khe giữa các Master để đảm bảo tính nhất quán của hạ tầng.

---

### 3. Luồng hoạt động và Cơ chế chuyển đổi (Failover)

Quy trình vận hành trong chế độ Failover tập trung vào việc duy trì tính liên tục của dịch vụ khi có sự cố xảy ra tại Master chính:

1. Initial Handshake: Khi khởi động, Minion cố gắng kết nối với Master đầu tiên trong danh sách. Nếu thành công, nó sẽ chỉ giữ kết nối Active với Master này để nhận lệnh. Các Master còn lại trong danh sách được đưa vào trạng thái "Standby".
2. Master Heartbeat & Monitoring: Minion liên tục kiểm tra tình trạng sức khỏe của Master hiện tại thông qua giao thức ZeroMQ. Nếu Master không phản hồi các gói tin kiểm tra (keep-alive), Minion sẽ ghi nhận sự cố.
3. Triggering Failover: Ngay khi phát hiện Master chính bị Down, Minion sẽ thực hiện quy trình chuyển đổi:

- Ngắt kết nối cũ.
- Thử kết nối với Master tiếp theo trong danh sách cấu hình.
- Gửi lại Public Key để xác thực nếu cần thiết.

1. Job Resumption: Sau khi chuyển đổi sang Master mới thành công, Minion bắt đầu lắng nghe lệnh từ Master dự phòng này. Mọi báo cáo kết quả (Reporting) từ thời điểm này sẽ được gửi về Master mới.
2. Recovery & Reversion: Tùy vào cấu hình, khi Master chính quay trở lại trạng thái Online, Minion có thể được thiết lập để tự động quay lại (Revert) kết nối với Master ưu tiên ban đầu nhằm đảm bảo đúng mô hình kiến trúc dự kiến.

---

### 4. Các đặc điểm kỹ thuật quan trọng

#### Data Synchronization

Hệ thống chỉ hoạt động ổn định khi các thành phần được đồng bộ:

- PKI Directory (`/etc/salt/pki/master`): Toàn bộ key của Minion phải giống hệt nhau trên các Master
- File Roots (`/etc/salt`): Logic cài đặt phải đồng nhất
- Pillar Roots (`/etc/pillar`): Dữ liệu biến số phải khớp

#### Fault Tolerance

- Khi một Master gặp sự cố, các Minion sẽ tự động loại bỏ Master đó khỏi luồng xử lý mà không cần can thiệp thủ công.
- Ngay khi Master đó quay trở lại (Online), các Minion sẽ tái thiết lập kết nối ZeroMQ ngay lập tức.

#### Key Management

- Rủi ro: Nếu bạn chỉ salt-key -A trên Master 1 mà quên Master 2, khi Master 1 down, hệ thống sẽ bị tê liệt hoàn toàn vì Master 2 không thể ra lệnh cho Minion.
- Giải pháp: Sử dụng cơ chế chia sẻ thư mục /etc/salt/pki/master thông qua hệ thống tệp tin dùng chung (NFS) hoặc đồng bộ liên tục.

---

## II. Cấu hình thực tế

Ở bài lab này, sử dụng 3 VM Ubuntu với các IP sau:

- Master 1: 10.1.1.136
- Master 2: 10.1.1.132
- Minion 1: 10.1.1.138

### Bước 1: Cài đặt salt-master và salt-minion trên các VM (cách cài đặt [tại đây](/docs/salt-install.md))

---

### Bước 2: Cấu hình Master

- Mở file `/etc/salt/master`

  ```bash
  interface: 0.0.0.0
  auto_accept: False
  worker_threads: 5

  file_roots:
    base:
      - /srv/salt

  pillar_roots:
    base:
      - /srv/pillar

  master_sign_pubkey: True
  ```

- Khởi động lại service salt-master
  ```bash
  systemctl restart salt-master
  ```
- Kiểm tra: `ls /etc/salt/pki/master/`
  ```bash
  master_sign.pem
  master_sign.pub
  ```

---

### Bước 3: Đồng bộ signing key giữa 2 master

- Trên master 1:
  ```bash
  scp /etc/salt/pki/master/master_sign.pem nmthanh@10.1.1.132:/etc/salt/pki/master/
  scp /etc/salt/pki/master/master_sign.pub nmthanh@10.1.1.132:/etc/salt/pki/master/
  ```
- Restart service master2:
  ```bash
  systemctl restart salt-master
  ```

---

### Bước 4: Copy public signing key sang minion

- Từ master1:
  ```bash
  scp /etc/salt/pki/master/master_sign.pub nmthanh@10.1.1.138:/etc/salt/pki/minion/
  ```
- Kiểm tra trên minion:
  ```bash
  ls /etc/salt/pki/minion/
  # kết quả phải có: master_sign.pub
  ```
- Tuyệt đối không copy master_sign.pem.

### Bước 5: Cấu hình minion Multi-Master

- Chỉnh sửa file cấu hình `/etc/salt/minion`

  ```bash
  master:
    - 10.1.1.136
    - 10.1.1.132

  master_type: failover #chỉ 1 master active
  random_master: True  #tránh dồn toàn bộ vào master1
  master_alive_internal: 60 #phát hiện master chết
  retry_dns: 0

  verify_master_pubkey_sign: True #bật xác thực chữ ký
  id: web01
  ```

- 2 Master đều có trạng thái hoạt động
  ![master1](/imgs/status-master-1.png)

  ![master2](/imgs/status-master-2.png)

### Bước 6: Test verify ở debug mode

- trên Minion:
  ```bash
  salt-minion -l debug
  ```

  - Kết quả thành công:
    Successfully verified signature of master public key
    Received signed and verified master pubkey
    Authentication successful
  - Kết quả thất bài:
    Failed to verify signature
    CRITICAL The Salt Master server's public key did not authenticate
- Chạy lại service:
  ```bash
  systemctl enable salt-minion
  systemctl start salt-minion
  ```

### Bước 7: Accept key trên 2 master

- Trên mỗi master chạy:
  ```bash
  salt-key -L
  salt-key -A
  ```

### Bước 8: Triển khai Nginx

- Tạo: `mkdir -p /srv/salt/nginx/files`
- Tạo file `/srv/salt/nginx/init.sls`:

  ```bash
  nginx:
    pkg.installed: []

    service.running:
      - enable: True
      - require:
        - pkg: nginx
  ```

- Apply từ master1: `salt '*' state.apply nginx`
- Apply từ master2: `salt '*' state.apply nginx`
- Phải ra kết quả giống nhau.

### Bước 9: Kiểm tra Failover

1. Kiểm tra xem minion đang lắng nghe master từ IP nào?
   ![master](/imgs/port-connect-master.png)

2. Test trạng thái từ master mà minion đang lắng nghe `salt 'web01' test.ping`
   ![master1-success](/imgs/test-master1.png)

- Multiple master sẽ chỉ hoạt động mà minion đang lắng nghe. VD: Minion đang lắng nghe master 1 thì chỉ có master 1 mới có thể điều khiển còn master 2 sẽ không điều khiển được.
  ![master2-fail](/imgs/Fail-master2.png)

3. Tắt master1: `systemctl stop salt-master`

- Khi tắt master1 thì minion sẽ lắng nghe sang master 2

4. Test từ master2: `salt '*' test.ping`

  ![master2-success](/imgs/test-master2.png)

-> Failover thành công.
