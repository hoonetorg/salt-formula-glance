
include:
{%- if pillar.glance.server.enabled %}
- glance.server
- glance.deploy


{%- if server.images %}
extend:
  /var/lib/glance/images:
    #file.directory:
    file:
      - require:
        - service: glance_services
{%- endif %}



{%- endif %}
