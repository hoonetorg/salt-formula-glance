{%- from "glance/map.jinja" import server with context %}
{%- if server.enabled %}

{%- if server.get('images', False) %}
/var/lib/glance/images:
  file.directory:
  - mode: 755
  - user: glance
  - group: glance

{%- for image in server.get('images', []) %}

glance_download_{{ image.name }}:
  cmd.run:
  - name: wget {{ image.source }}
  - unless: "test -e {{ image.file }}"
  - cwd: /var/lib/glance/images
  - require:
    - file: /var/lib/glance/images

#FIXME: openstack image create "Cirros 0.3.4" --file cirros-0.3.4-x86_64-disk.raw --disk-format raw --container-format bare --public --property hw_scsi_model=virtio-scsi --property hw_disk_bus=scsi --property hw_qemu_guest_agent=yes --property os_require_quiesce=yes
glance_install_{{ image.name }}:
  cmd.wait:
  - name: source /root/keystonerc; glance image-create --name '{{ image.name }}' --is-public {{ image.public }} --container-format bare --disk-format {{ image.format }} < {{ image.file }}
  - cwd: /var/lib/glance/images
  - require:
    - file: /var/lib/glance/images
  - watch:
    - cmd: glance_download_{{ image.name }}

{%- endfor %}

{%- for image_name, image in server.get('image', {}).iteritems() %}

glance_download_{{ image_name }}:
  cmd.run:
  - name: wget {{ image.source }}
  - unless: "test -e {{ image.file }}"
  - cwd: /var/lib/glance/images
  - require:
    - file: /var/lib/glance/images

glance_install_image_{{ image_name }}:
  cmd.run:
  - name: source /root/keystonerc; glance image-create --name '{{ image_name }}' --is-public {{ image.public }} --container-format bare --disk-format {{ image.format }} < /var/lib/glance/images/{{ image.file }}
  - require:
    - file: /var/lib/glance/images
    - cmd: glance_download_{{ image_name }}
  - unless:
    - cmd: source /root/keystonerc && glance image-list | grep {{ image_name }}

{%- endfor %}

{%- endif %}

{%- if server.policy is defined %}

{%- for key, policy in server.policy.iteritems() %}

policy_{{ key }}:
  file.replace:
  - name: /etc/glance/policy.json
  - pattern: "[\"']{{ key }}[\"']:.*"
  {# unfortunatately there's no jsonify filter so we have to do magic :-( #}
  - repl: '"{{ key }}": {% if policy is iterable %}[{%- for rule in policy %}"{{ rule }}"{% if not loop.last %}, {% endif %}{%- endfor %}]{%- else %}"{{ policy }}"{%- endif %},'

{%- endfor %}

{%- endif %}

{%- endif %}

glance_deploy__empty_sls_prevent_error:
  cmd.run:
    - name: true
    - unless: true
