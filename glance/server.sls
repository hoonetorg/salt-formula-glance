{%- from "glance/map.jinja" import server with context %}
{%- if server.enabled %}

glance_packages:
  pkg.installed:
  - names: {{ server.pkgs }}

{%- if not salt['user.info'](server.user.name) %}
glance_user:
  user.present:
    - name: {{server.user.name}}
    - home: {{server.user.home}}
    - uid: {{server.user.uid}}
    - gid: {{server.group.gid}}
    - shell: {{server.user.shell}}
    - fullname: {{server.user.fullname}}
    - system: True
    - require_in:
      - pkg: glance_packages

glance_group:
  group.present:
    - name: {{server.group.name}}
    - gid: {{server.group.gid}}
    - system: True
    - require_in:
      - pkg: glance_packages
      - user: glance_user
{%- endif %}

{%- if server.get('storage').get('engine') in ['rbd'] %}
/etc/ceph/ceph.client.{{server.storage.user|default('glance')}}.keyring:
  file.managed:
    - group: {{server.group.name}}
    - mode: "0660"
    - require_in:
      - file: /etc/glance/glance-api.conf
{%- endif %}

/etc/glance/glance-cache.conf:
  file.managed:
  - source: salt://glance/files/{{ server.version }}/glance-cache.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: glance_packages

/etc/glance/glance-registry.conf:
  file.managed:
  - source: salt://glance/files/{{ server.version }}/glance-registry.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: glance_packages

/etc/glance/glance-scrubber.conf:
  file.managed:
  - source: salt://glance/files/{{ server.version }}/glance-scrubber.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: glance_packages

/etc/glance/glance-api.conf:
  file.managed:
  - source: salt://glance/files/{{ server.version }}/glance-api.conf.{{ grains.os_family }}
  - template: jinja
  - require:
    - pkg: glance_packages

/etc/glance/glance-api-paste.ini:
  file.managed:
  - source: salt://glance/files/{{ server.version }}/glance-api-paste.ini
  - template: jinja
  - require:
    - pkg: glance_packages

glance_install_database:
  cmd.run:
  - name: glance-manage db_sync
  - user: {{server.user.name}}
  - group: {{server.group.name}}
  - watch:
    - file: /etc/glance/glance-cache.conf
    - file: /etc/glance/glance-registry.conf
    - file: /etc/glance/glance-scrubber.conf
    - file: /etc/glance/glance-api.conf
    - file: /etc/glance/glance-api-paste.ini

/var/log/glance:
  file.directory:
  - user: {{server.user.name}}
  - group: {{server.group.name}}
  - recurse:
    - user
    - group
  - require:
    - cmd: glance_install_database
  - require_in:
    - service: glance_services

glance_services:
  service.{{ server.service_state }}:
    - names: {{ server.services }}
    {% if server.service_state in [ 'running', 'dead' ] %}
    - enable: {{ server.service_enable }}
    {% endif %}
    - require:
      - cmd: glance_install_database

{%- endif %}
