#!pyobjects
# -*- mode: python -*-
from salt.utils import dictupdate
import yaml

conf_path = '/etc/elasticsearch/'
log_path = '/var/log/elasticsearch/'
data_path = '/var/lib/elasticsearch/'

packages_es = pillar('gentoo:portage:packages:app-misc/elasticsearch', {})
es_version = packages_es.get('version', '=7.0.0')
es_version_short = es_version.rsplit('-', 1)[0].lstrip('-~*<>=')

File.directory(
  conf_path, create=True,
  mode=755, user='root', group='root')

File.directory(
  log_path, create=True,
  mode=755, user='elasticsearch', group='elasticsearch')

File.directory(
  data_path, create=True,
  mode=755, user='elasticsearch', group='elasticsearch')

fqdn = grains('fqdn')
fqdn_ipv6 = grains('fqdn_ipv6')
nodes = pillar('elastic:nodes', {})
master_nodes = nodes.get('master', {})
if not 'data' in nodes:
  nodes['data'] = master_nodes
if not 'ingest' in nodes:
  nodes['ingest'] = nodes['data']

data_count = pillar('elastic:data-dir-count', False)
if data_count:
  _dirs = [data_path + 'data' + str(i) for i in range(0, data_count)]
  data_dir = ','.join(_dirs)
  for d in _dirs:
    File.directory(
      d, create=True,
      mode=755, user='elasticsearch', group='elasticsearch',
      require=[File(data_path)])
else:
  data_dir = data_path

limits = pillar('elastic:limits', {})
l_nofile = limits.get('nofile', 1048576)
l_memlock = limits.get('memlock', 'unlimited')
max_map_count = limits.get('max_map_count', 262144)
max_threads = limits.get('max_threads', 4096)

jvm = pillar('elastic:jvm', {})
jvm_heap_size = jvm.get('heap_size', '1g')
jvm_stack_size = jvm.get('stack_size', '1m')
jvm_extra_options = jvm.get('extra_options', {})
jvm_gc_type = jvm.get('gc_type', 'CMS')
jvm_gc_occupancy_value = jvm.get('gc_occupancy_value', '75')

tls = pillar('elastic:tls', {})
tls_enabled = tls.get('enabled', False)
if tls:
  tls_transport = tls.get('transport', {})
  tls_http = tls.get('http', {})

# defaults
config = {
  'node': {
    'name': '${HOSTNAME}',
    'master': False, 'data': False, 'ingest': False,
    'max_local_storage_nodes': 1,
  },
  'bootstrap': {'memory_lock': True},
  'discovery': {},
  'cluster': {},
  'network': { 'host': '${HOSTNAME}' },
  'http': { 'port': 9200 },
  'gateway': {
    'expected_master_nodes': len(master_nodes),
    'expected_data_nodes': len(nodes['data']),
    'recover_after_time': '5m',
    'recover_after_master_nodes': len(master_nodes)/2,
  },
}

if es_version_short.startswith('7'):
  config['cluster']['initial_master_nodes'] = pillar('elastic:initial_master_nodes', master_nodes)
  config['discovery']['seed_hosts'] = pillar('elastic:seed_hosts', master_nodes)
else:
  config['discovery']['zen.ping.unicast.hosts'] = pillar('elastic:seed_hosts', master_nodes)

for node_type in ('master', 'data', 'ingest'):
  if any(name in nodes[node_type] for name in (fqdn, fqdn_ipv6)):
    config['node'][node_type] = True

if tls:
  config['opendistro_security'] = {
    'ssl': {
      'http': {
        'enabled': tls_http.get('enabled', tls_enabled),
        'enable_openssl_if_available': True,
        'pemcert_filepath': 'http-cert.pem',
        'pemkey_filepath': 'http-key.pem',
        'pemtrustedcas_filepath': 'http-ca.pem',
        'clientauth_mode': tls_http.get('clientauth_mode', 'OPTIONAL')
      },
      'transport': {
        'enabled': tls_transport.get('enabled', tls_enabled),
        'enable_openssl_if_available': True,
        'pemcert_filepath': 'transport-cert.pem',
        'pemkey_filepath': 'transport-key.pem',
        'pemtrustedcas_filepath': 'transport-ca.pem',
        'enforce_hostname_verification': True
      },
    }
  }

s3 = pillar('elastic:repository-s3', {})
if len(s3) > 0:
  s3_prefix = 's3.client.default.'
  for param,value in s3['client'].items():
    config[s3_prefix + param] = value

dictupdate.update(config, pillar('elastic:config'))

File.managed(
  conf_path + 'elasticsearch.yml',
  mode=644, user='root', group='root',
  contents="# This file is generated by Salt\n" + yaml.dump(config),
  require=[File(conf_path)])

File.managed(
  conf_path + 'jvm.options',
  mode=644, user='root', group='root',
  template='jinja', source='salt://elasticsearch/files/jvm.options.tpl',
  defaults={'heap_size': jvm_heap_size, 'stack_size': jvm_stack_size,
            'gc_type': jvm_gc_type, 'gc_occupancy_value': jvm_gc_occupancy_value,
            'extra_options': jvm_extra_options},
  require=[File(conf_path)])

File.managed(
  '/etc/conf.d/elasticsearch',
  mode=644, user='root', group='root',
  template='jinja', source="salt://elasticsearch/files/elasticsearch.confd.tpl",
  defaults={
    'conf_dir': conf_path, 'log_dir': log_path, 'data_dir': data_dir,
    'es_java_opts': '', 'l_nofile': l_nofile, 'l_memlock': l_memlock,
    'max_map_count': max_map_count, 'max_threads': max_threads, 'es_startup_sleep_time': 10})

if tls:
  for proto in ('transport', 'http'):
    for pemtype in ('cert', 'key', 'ca'):
      File.managed(
        conf_path + proto + '-' + pemtype + '.pem',
        mode=600, user='elasticsearch', group='elasticsearch',
        contents=tls[proto].get(pemtype, tls.get(pemtype, '')),
        require=[File(conf_path)])

File.managed(
  '/etc/security/limits.d/elasticsearch.conf',
  mode=644, user='root', group='root',
  contents='\n'.join([
    "elasticsearch soft nofile {0}".format(l_nofile),
    "elasticsearch hard nofile {0}".format(l_nofile),
    "elasticsearch soft memlock {0}".format(l_memlock),
    "elasticsearch hard memlock {0}".format(l_memlock)]))
