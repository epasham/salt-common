{% set arch_conf = salt['pillar.get']('arch_conf', False) %}
eselect-profile:
  eselect.set:
    - name: profile
    {% if arch_conf and arch_conf.get('profile', False) %}
    - target: '{{ arch_conf["profile"] }}'
    {% elif grains['osarch'] == 'x86' %}
    - target: default/linux/x86/17.0/hardened
    {% elif grains['osarch'] == 'x86_64' %}
    - target: default/linux/amd64/17.0/no-multilib/hardened
    {% elif grains['osarch'] == 'armv6l' %}
    - target: hardened/linux/arm/armv6j
    {% endif %}
