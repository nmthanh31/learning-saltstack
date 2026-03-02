# Triển khai CI/CD tích hợp GitHub và SaltStack

---

## Mục lục
- [I. Tổng quan bài tập](#i)
    - [1. Mục tiêu đề bài](#1)
    - [2. Tổng quan kiến trúc](#2)
- [II. Cấu hình thực tế](#ii)

---

## <a name="i">I. Tổng quan bài tập</a>

---

### <a name="1">1. Mục tiêu đề tài</a>
Xây dựng hệ thống CI/CD tích hợp Git với SaltStack nhằm:
- Quản lý cấu hình bằng Git (Version Control)
- Tự động kiểm tra (CI)
- Tự động triển khai cấu hình (CD)
- Đảm bảo idempotency 
- Ngăn chặn configuration drift
- Có khả năng mở rộng trong môi trường production

### <a name="2">2. Tổng quan kiến trúc</a>
Hệ thống này sẽ sử dụng GitLab làm trung tâm quản lý source code và pipeline CI/CD.
|VM             |Role           |
|---------------|---------------|
|VM1: 10.1.1.136|Salt Master    |
|VM2: 10.1.1.139|Salt Minion    |

Luồng hoạt động của kiến trúc:
![act-flow](/imgs/act-flow.png)
- Dev chính sứa state/config
- Commit và push lên GitLab
- GitLab CI pipeline được kích hoạt
- Pipeline thực hiện:
    - Kiểm tra syntax
    - SSH vào Salt Master
    - Thực thi state.apply
- Salt Master triển khai xuống Minion
- Nginx được cập nhật theo Desired State

## <a name="ii">II. Cấu hình thực tế </a>

---

### Bước 1: Cài đặt Salt-Stack trên VM1 Vm2 (Hướng dẫn [tại đây](/docs/salt-install.md))
### Bước 2: Viết file cấu hình nginx cho Salt (Như bài [salt-single-master](/docs/salt-single-master.md))
### Bước 3: 