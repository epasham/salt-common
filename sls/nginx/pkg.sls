{% import 'pkg/common' as pkg %}
{% set makeconf_nginx_modules_http = '''access auth_basic autoindex browser charset empty_gif fastcgi geo geoip gzip gzip_static limit_req limit_zone lua map memcached proxy realip referer rewrite scgi split_clients ssi ssl reqstat upstream_keepalive upstream_least_conn upstream_rbtree limit_conn upstream_session_sticky stub_status upstream_check upstream_consistent_hash upstream_ip_hash userid uwsgi''' -%}
{% set makeconf_nginx_modules_mail = 'smtp imap pop3' -%}

manage-nginx-modules:
  augeas.change:
    - context: /files/etc/portage/make.conf
    - changes:
      - set NGINX_MODULES_HTTP '"{{ makeconf_nginx_modules_http }}"'
      - set NGINX_MODULES_MAIL '"{{ makeconf_nginx_modules_mail }}"'

# TODO: move this to separate file
dev-libs/libpcre:
  portage_config.flags:
    - use:
      - jit

www-servers/nginx:
  pkg.installed:
    - pkgs:
      - {{ pkg.gen_atom('www-servers/nginx') }}
    - watch:
      - augeas: manage-nginx-modules
  {{ pkg.gen_portage_config('www-servers/nginx', watch_in={'pkg': 'www-servers/nginx'})|indent(8) }}

