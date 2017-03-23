#!pydsl
# -*- mode: python -*-
from salt.utils import dictupdate
import yaml

hosts = __salt__['pillar.get']('elastic:hosts', [])

# defaults
config = {
  'client': {
    'hosts': hosts,
    'master_only': False
  },
  'logging': {
    'loglevel': 'INFO',
    'logformat': 'default'
  }
}

dictupdate.update(config, __salt__['pillar.get']('elastic:curator:config', {}))

include('python.dev-python.elasticsearch-curator')

state('/etc/elasticsearch/curator.yml').file.managed(
  mode=644, user='root', group='root', makedirs=True,
  contents="# This file is generated by Salt\n" + yaml.dump(config))

state('/etc/elasticsearch/curator-actions.yml').file.managed(
  mode=644, user='root', group='root', makedirs=True,
  contents="# This file is generated by Salt\n" + yaml.dump({
    'actions': __salt__['pillar.get']('elastic:curator:actions', {})
  }))

cron = __salt__['pillar.get']('elastic:curator:cron')
if cron:
  state('curator-cron').cron.present(
    identifier='curator-cron', hour=cron.get('hour', '1'), minute=cron.get('minute', '0'),
    user=cron.get('user', 'elasticsearch'),
    name='curator --config /etc/elasticsenarch/curator.yml /etc/elasticsearch/curator-actions.yml').\
    require(pkg='dev-python/elasticsearch-curator')
