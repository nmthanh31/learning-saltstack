nginx_pkg:
  pkg.installed:
    - name: nginx

/var/www/html/index.html:
  file.managed:
    - source: salt://nginx/files/index.html
    - user: www-data
    - group: www-data
    - mode: 644
    - makedirs: True

nginx:
  pkg.install: []

  service.running:
    - enable: True
    - reload: True
    - watch:
      - file: /var/www/html/index.html