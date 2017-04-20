include:
  - python.python2
  - python.python3

app-eselect/eselect-python:
  portage_config.flags:
    - accept_keywords: []

dev-lang/python-exec:
  portage_config.flags:
    - accept_keywords: []

pkg_python-config:
  pkg.latest:
    - pkgs:
      - dev-lang/python-exec
      - app-eselect/eselect-python
    - require:
      - portage_config: app-eselect/eselect-python
      - portage_config: dev-lang/python-exec

eselect-python3:
  eselect.set:
    - name: python
    - action_parameter: '--python3'
    - target: 'python3.4'
    - require:
      - pkg: pkg_python-config

app-admin/python-updater:
  pkg.purged
