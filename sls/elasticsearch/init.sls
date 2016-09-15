include:
  - java.icedtea3
  - elasticsearch.pkg
  - elasticsearch.config

elasticsearch:
  service.running:
    - enable: True
    - watch:
      - pkg: icedtea3
      - pkg: elasticsearch_pkg
      - file: /etc/elasticsearch/elasticsearch.yml
