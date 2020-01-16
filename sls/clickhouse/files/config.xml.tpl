{% set config = salt['pillar.get']('clickhouse', {}) %}
{% set hostname = __grains__.get('fqdn') %}
<!--# Managed by Salt -->
<?xml version="1.0"?>
<yandex>
  <logger>
    <!-- Possible levels: https://github.com/pocoproject/poco/blob/develop/Foundation/include/Poco/Logger.h#L105 -->
    <level>information</level>
    <log>/var/log/clickhouse-server/clickhouse-server.log</log>
    <errorlog>/var/log/clickhouse-server/clickhouse-server.err.log</errorlog>
    <size>1000M</size>
    <count>10</count>
    <!-- <console>1</console> -->
    <!-- Default behavior is autodetection (log to console if not daemon mode and is tty) -->
  </logger>

  <display_name>{{ hostname }}</display_name>
  <http_port>{{ config.get('server:http_port', 8123) }}</http_port>
  <tcp_port>{{ config.get('server:tcp_port', 9000) }}</tcp_port>
  <!-- For HTTPS and SSL over native protocol. -->
  <!--
    <https_port>8443</https_port>
    <tcp_port_secure>9440</tcp_port_secure>
    -->
  <!-- Used with https_port and tcp_port_secure. Full ssl options list: https://github.com/ClickHouse-Extras/poco/blob/master/NetSSL_OpenSSL/include/Poco/Net/SSLManager.h#L71 -->

  <!-- Default root page on http[s] server. For example load UI from https://tabix.io/ when opening http://localhost:8123 -->
  <!--
    <http_server_default_response><![CDATA[<html ng-app="SMI2"><head><base href="http://ui.tabix.io/"></head><body><div ui-view="" class="content-ui"></div><script src="http://loader.tabix.io/master.js"></script></body></html>]]></http_server_default_response>
    -->
  <!-- Port for communication between replicas. Used for data exchange. -->
  <interserver_http_port>{{ config.get('server:interserver_http_port', 9009) }}</interserver_http_port>
  <!-- Hostname that is used by other replicas to request this server.
         If not specified, than it is determined analoguous to 'hostname -f' command.
         This setting could be used to switch replication to another network interface.
      -->
  <interserver_http_host>{{ hostname }}</interserver_http_host>
  <!-- Listen specified host. use :: (wildcard IPv6 address), if you want to accept connections both with IPv4 and IPv6 from everywhere. -->
  <!-- <listen_host>::</listen_host> -->
  <!-- Same for hosts with disabled ipv6: -->
  <listen_host>{{ __grains__.get('fqdn_ip6')[0] }}</listen_host>
  <!-- Default values - try listen localhost on ipv4 and ipv6: -->
  <!--
    <listen_host>::1</listen_host>
    <listen_host>127.0.0.1</listen_host>
    -->
  <!-- Don't exit if ipv6 or ipv4 unavailable, but listen_host with this protocol specified -->
  <!-- <listen_try>0</listen_try> -->
  <!-- Allow listen on same address:port -->
  <!-- <listen_reuse_port>0</listen_reuse_port> -->
  <!-- <listen_backlog>64</listen_backlog> -->
  <max_connections>{{ config.get('server:max_connections', 4096) }}</max_connections>
  <keep_alive_timeout>{{ config.get('server:keep_alive_timeout', 3) }}</keep_alive_timeout>
  <!-- Maximum number of concurrent queries. -->
  <max_concurrent_queries>{{ config.get('server:max_concurrent_queries', 100) }}</max_concurrent_queries>
  <!-- Set limit on number of open files (default: maximum). This setting makes sense on Mac OS X because getrlimit() fails to retrieve
         correct maximum value. -->
  <!-- <max_open_files>262144</max_open_files> -->
  <!-- Size of cache of uncompressed blocks of data, used in tables of MergeTree family.
         In bytes. Cache is single for server. Memory is allocated only on demand.
         Cache is used when 'use_uncompressed_cache' user setting turned on (off by default).
         Uncompressed cache is advantageous only for very short queries and in rare cases.
      -->
  <uncompressed_cache_size>{{ config.get('server:uncompressed_cache_size', 8589934592 }}</uncompressed_cache_size>
  <!-- Approximate size of mark cache, used in tables of MergeTree family.
         In bytes. Cache is single for server. Memory is allocated only on demand.
         You should not lower this value.
      -->
  <mark_cache_size>{{ config.get('server:mark_cache_size', 5368709120 }}</mark_cache_size>
  <!-- Path to data directory, with trailing slash. -->
  <path>/var/lib/clickhouse/</path>
  <!-- Path to temporary data for processing hard queries. -->
  <tmp_path>/var/lib/clickhouse/tmp/</tmp_path>
  <!-- Directory with user provided files that are accessible by 'file' table function. -->
  <user_files_path>/var/lib/clickhouse/user_files/</user_files_path>
  <!-- Path to configuration file with users, access rights, profiles of settings, quotas. -->
  <users_config>users.xml</users_config>
  <!-- Default profile of settings. -->
  <default_profile>default</default_profile>
  <!-- System profile of settings. This settings are used by internal processes (Buffer storage, Distibuted DDL worker and so on). -->
  <!-- <system_profile>default</system_profile> -->
  <!-- Default database. -->
  <default_database>default</default_database>
  <!-- Server time zone could be set here.

         Time zone is used when converting between String and DateTime types,
          when printing DateTime in text formats and parsing DateTime from text,
          it is used in date and time related functions, if specific time zone was not passed as an argument.

         Time zone is specified as identifier from IANA time zone database, like UTC or Africa/Abidjan.
         If not specified, system time zone at server startup is used.

         Please note, that server could display time zone alias instead of specified name.
         Example: W-SU is an alias for Europe/Moscow and Zulu is an alias for UTC.
    -->
  <!-- <timezone>Europe/Moscow</timezone> -->
  <!-- You can specify umask here (see "man umask"). Server will apply it on startup.
         Number is always parsed as octal. Default umask is 027 (other users cannot read logs, data files, etc; group can only read).
    -->
  <!-- <umask>022</umask> -->
  <!-- Configuration of clusters that could be used in Distributed tables.
         https://clickhouse.yandex/docs/en/table_engines/distributed/
      -->

  {% set clickhouse_shards = config.get('cluster:shards', {}) %}
  {% if len(clickhouse_shards) > 0 %}
  <load_balancing>in_order</load_balancing>
  <insert_quorum>2</insert_quorum>
  <remote_servers>
    <rbk>
      {% for shard in clickhouse_shards %}
      <shard>
        <weight>{{ shard['weight'] }}</weight>
        <internal_replication>true</internal_replication>
        <replica>
          <host>{{ shard['node'] }}</host>
          <port>9000</port>
        </replica>
        {% for replica in shard['replicas'] %}
        <replica>
          <host>{{ replica }}</host>
          <port>9000</port>
        </replica>
        {% endfor %}
      </shard>
	  {% endfor %}
    </rbk>
  </remote_servers>
  {% endif %}

  <!-- If element has 'incl' attribute, then for it's value will be used corresponding substitution from another file.
         By default, path to file with substitutions is /etc/metrika.xml. It could be changed in config in 'include_from' element.
         Values for substitutions are specified in /yandex/name_of_substitution elements in that file.
      -->
  <!-- ZooKeeper is used to store metadata about replicas, when using Replicated tables.
         Optional. If you don't use replicated tables, you could omit that.

         See https://clickhouse.yandex/docs/en/table_engines/replication/
      -->
  <!--    <zookeeper incl="zookeeper-servers" optional="true" /> -->
  {% set zookeeper_nodes = salt['pillar.get']('zookeeper:nodes', {}) %}
  {% set zookeeper_port = config.get('zookeeper_port', 2181) %}
  <zookeeper>
      {% for node_index in range(1, len(zookeeper_nodes) + 1) %}
      <node index="{{ node_index }}">
          <host>{{ zookeeper_nodes[node_index] }}</host>
          <port>{{ zookeeper_port }}</port>
      </node>
      {% endfor %}
  </zookeeper>
  <!-- Substitutions for parameters of replicated tables.
          Optional. If you don't use replicated tables, you could omit that.

         See https://clickhouse.yandex/docs/en/table_engines/replication/#creating-replicated-tables
      -->
  <macros>
  {% for shard in clickhouse_shards %}
    {% if hostname == shard['node'] %}
    <shard>s{{ shard }}</shard>
    <replica>r1</replica>
    {% elif hostname in shard['replicas'] %}
    <shard>s{{ shard }}</shard>
    <replica>r{{ shards['replicas'].index(hostname) + 2}}</replica>
    {% endif %}
  {% endfor %}
  </macros>
  <!-- Reloading interval for embedded dictionaries, in seconds. Default: 3600. -->
  <builtin_dictionaries_reload_interval>{{ config.get('server:builtin_dictionaries_reload_interval', 3600 }}</builtin_dictionaries_reload_interval>
  <!-- Maximum session timeout, in seconds. Default: 3600. -->
  <max_session_timeout>{{ config.get('server:max_session_timeout', 3600 }}</max_session_timeout>
  <!-- Default session timeout, in seconds. Default: 60. -->
  <default_session_timeout>{{ config.get('server:default_session_timeout', 60 }}</default_session_timeout>
  <!-- Sending data to Graphite for monitoring. Several sections can be defined. -->
  <!--
        interval - send every X second
        root_path - prefix for keys
        hostname_in_path - append hostname to root_path (default = true)
        metrics - send data from table system.metrics
        events - send data from table system.events
        asynchronous_metrics - send data from table system.asynchronous_metrics
    -->
  <graphite>
    <host>{{ config.get('server:graphite:host', 'carbon1.bst1.rbkmoney.net' }}</host>
    <port>{{ config.get('server:graphite:port', 2003 }}</port>
    <timeout>{{ config.get('server:graphite:timeout', 0.1 }}</timeout>
    <interval>{{ config.get('server:graphite:interval', 1 }}</interval>
    <metrics>{{ config.get('server:graphite:metrics', 'true' }}</metrics>
    <events>{{ config.get('server:graphite:events', 'true' }}</events>
    <asynchronous_metrics>{{ config.get('server:graphite:asynchronous_metrics', 'false' }}</asynchronous_metrics>
  </graphite>
  <!-- Query log. Used only for queries with setting log_queries = 1. -->
  <query_log>
    <!-- What table to insert data. If table is not exist, it will be created.
             When query log structure is changed after system update,
              then old table will be renamed and new table will be created automatically.
        -->
    <database>system</database>
    <table>query_log</table>
    <!--
            PARTITION BY expr https://clickhouse.yandex/docs/en/table_engines/custom_partitioning_key/
            Example:
                event_date
                toMonday(event_date)
                toYYYYMM(event_date)
                toStartOfHour(event_time)
        -->
    <partition_by>toYYYYMM(event_date)</partition_by>
    <!-- Interval of flushing data. -->
    <flush_interval_milliseconds>7500</flush_interval_milliseconds>
  </query_log>
  <!-- Uncomment if use part_log
    <part_log>
        <database>system</database>
        <table>part_log</table>

        <flush_interval_milliseconds>7500</flush_interval_milliseconds>
    </part_log>
    -->
  <!-- Parameters for embedded dictionaries, used in Yandex.Metrica.
         See https://clickhouse.yandex/docs/en/dicts/internal_dicts/
    -->
  <!-- Path to file with region hierarchy. -->
  <!-- <path_to_regions_hierarchy_file>/opt/geo/regions_hierarchy.txt</path_to_regions_hierarchy_file> -->
  <!-- Path to directory with files containing names of regions -->
  <!-- <path_to_regions_names_files>/opt/geo/</path_to_regions_names_files> -->
  <!-- Configuration of external dictionaries. See:
         https://clickhouse.yandex/docs/en/dicts/external_dicts/
    -->
  <dictionaries_config>*_dictionary.xml</dictionaries_config>
  <!-- Uncomment if you want data to be compressed 30-100% better.
         Don't do that if you just started using ClickHouse.
      -->
  <compression>
    <!--
        <!- - Set of variants. Checked in order. Last matching case wins. If nothing matches, lz4 will be used. - ->
        <case>

            <!- - Conditions. All must be satisfied. Some conditions may be omitted. - ->
            <min_part_size>10000000000</min_part_size>        <!- - Min part size in bytes. - ->
            <min_part_size_ratio>0.01</min_part_size_ratio>   <!- - Min size of part relative to whole table size. - ->

            <!- - What compression method to use. - ->
            <method>zstd</method>
        </case>
    -->
  </compression>
  <!-- Allow to execute distributed DDL queries (CREATE, DROP, ALTER, RENAME) on cluster.
         Works only if ZooKeeper is enabled. Comment it if such functionality isn't required. -->
  <distributed_ddl>
    <!-- Path in ZooKeeper to queue with DDL queries -->
    <path>/clickhouse/task_queue/ddl</path>
    <!-- Settings from this profile will be used to execute DDL queries -->
    <!-- <profile>default</profile> -->
  </distributed_ddl>
  <!-- Settings to fine tune MergeTree tables. See documentation in source code, in MergeTreeSettings.h -->
  <!--
    <merge_tree>
        <max_suspicious_broken_parts>5</max_suspicious_broken_parts>
    </merge_tree>
    -->
  <!-- Protection from accidental DROP.
         If size of a MergeTree table is greater than max_table_size_to_drop (in bytes) than table could not be dropped with any DROP query.
         If you want do delete one table and don't want to restart clickhouse-server, you could create special file <clickhouse-path>/flags/force_drop_table and make DROP once.
         By default max_table_size_to_drop is 50GB, max_table_size_to_drop=0 allows to DROP any tables.
         Uncomment to disable protection.
    -->
  <!-- <max_table_size_to_drop>0</max_table_size_to_drop> -->

  <!-- Directory in <clickhouse-path> containing schema files for various input formats.
         The directory will be created if it doesn't exist.
      -->
  <format_schema_path>/var/lib/clickhouse/format_schemas/</format_schema_path>
</yandex>