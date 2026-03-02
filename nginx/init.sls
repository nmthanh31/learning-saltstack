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