# -*- coding: utf-8 -*-
# vim: ft=sls

{% from "glance/map.jinja" import server with context %}
{% set pcs = server.get('pcs', {}) %}

{# set pcs = salt['pillar.get']('glance:server:pcs', {}) #}

{% if pcs.glance_cib is defined and pcs.glance_cib %}
glance_pcs__cib_present_{{pcs.glance_cib}}:
  pcs.cib_present:
    - cibname: {{pcs.glance_cib}}
{% endif %}

{% if 'resources' in pcs %}
{% for resource, resource_data in pcs.resources.items()|sort %}
glance_pcs__resource_present_{{resource}}:
  pcs.resource_present:
    - resource_id: {{resource}}
    - resource_type: "{{resource_data.resource_type}}"
    - resource_options: {{resource_data.resource_options|json}}
{% if pcs.glance_cib is defined and pcs.glance_cib %}
    - require:
      - pcs: glance_pcs__cib_present_{{pcs.glance_cib}}
    - require_in:
      - pcs: glance_pcs__cib_pushed_{{pcs.glance_cib}}
    - cibname: {{pcs.glance_cib}}
{% endif %}
{% endfor %}
{% endif %}

{% if 'constraints' in pcs %}
{% for constraint, constraint_data in pcs.constraints.items()|sort %}
glance_pcs__constraint_present_{{constraint}}:
  pcs.constraint_present:
    - constraint_id: {{constraint}}
    - constraint_type: "{{constraint_data.constraint_type}}"
    - constraint_options: {{constraint_data.constraint_options|json}}
{% if pcs.glance_cib is defined and pcs.glance_cib %}
    - require:
      - pcs: glance_pcs__cib_present_{{pcs.glance_cib}}
    - require_in:
      - pcs: glance_pcs__cib_pushed_{{pcs.glance_cib}}
    - cibname: {{pcs.glance_cib}}
{% endif %}
{% endfor %}
{% endif %}

{% if pcs.glance_cib is defined and pcs.glance_cib %}
glance_pcs__cib_pushed_{{pcs.glance_cib}}:
  pcs.cib_pushed:
    - cibname: {{pcs.glance_cib}}
{% endif %}

keytone_pcs__empty_sls_prevent_error:
  cmd.run:
    - name: true
    - unless: true
