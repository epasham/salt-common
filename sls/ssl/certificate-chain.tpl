# This file is generated by Salt
{% for cert in salt['pillar.get']('pki:tls:'+cert_chain_key+':cert-chain') %}
-----BEGIN CERTIFICATE-----
{{ cert.rstrip('\n') }}
-----END CERTIFICATE-----
{% endfor %}