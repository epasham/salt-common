# Dynamic config file for portage(5) generated by salt-minion(1)
#     DO NOT EDIT THIS FILE BY HAND -- YOUR CHANGES WILL BE OVERWRITTEN
{% if packagefile == 'keywords' %}
 {% for atom in packagespillar recursive %}
  {% if packagespillar[atom].kwrd is defined %}
{% if packagespillar[atom].version is defined %}={% endif %}{{ atom }}{% if packagespillar[atom].version is defined %}-{{ packagespillar[atom].version }}{% endif %} {{ packagespillar[atom].kwrd }}
  {% endif %}
 {% endfor %}
{% elif packagefile == 'use' %}
 {% for atom in packagespillar recursive %}
  {% if packagespillar[atom].use is defined %}
{{ atom }} {{ packagespillar[atom].use }}
  {% endif %}
 {% endfor %}
{% endif %}