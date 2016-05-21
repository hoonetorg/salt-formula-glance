{%- from "glance/map.jinja" import server with context %}
{%- if server.enabled %}

{%- if server.images %}
/var/lib/glance/images:
  file.directory:
  - mode: 755
  - user: glance
  - group: glance
  - require:
    - service: glance_services

{%- for image in server.get('images', []) %}

glance_download_{{ image.name }}:
  cmd.run:
  - name: wget {{ image.source }}
  - unless: "test -e {{ image.file }}"
  - cwd: /var/lib/glance/images
  - require:
    - file: /var/lib/glance/images

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

{%- endif %}
