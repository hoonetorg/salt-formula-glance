#!jinja|yaml
{% set node_ids = salt['pillar.get']('glance:server:pcs:node_ids') -%}
{% set admin_node_id = salt['pillar.get']('glance:server:pcs:admin_node_id') -%}

# node_ids: {{node_ids|json}}
# admin_node_id: {{admin_node_id}}

{% for node_id in node_ids %}
glance_orchestration__install_{{node_id}}:
  salt.state:
    - tgt: {{node_id}}
    - expect_minions: True
    - sls: glance.server
    - require_in:
      - salt: glance.pcs
{% endfor %}

glance_orchestration__pcs:
  salt.state:
    - tgt: {{admin_node_id}}
    - expect_minions: True
    - sls: glance.pcs

glance_orchestration__deploy:
  salt.state:
    - tgt: {{admin_node_id}}
    - expect_minions: True
    - sls: glance.deploy
    - require:
      - salt: glance_orchestration__pcs
