{% macro extract_form_metrics(conversions_column) %}
  (
    SELECT
      CAST(JSON_VALUE(item, '$.value') AS INT64)
    FROM UNNEST(JSON_EXTRACT_ARRAY({{ conversions_column }})) AS item
    WHERE JSON_VALUE(item, '$.action_type') = 'offsite_conversion.fb_pixel_custom.TypeformSubmit'
  ) AS form_submit,
  (
    SELECT
      CAST(JSON_VALUE(item, '$.value') AS INT64)
    FROM UNNEST(JSON_EXTRACT_ARRAY({{ conversions_column }})) AS item
    WHERE JSON_VALUE(item, '$.action_type') = 'offsite_conversion.fb_pixel_custom.TypeformFirstInteraction'
  ) AS form_interaction
{% endmacro %}

{% macro generate_action_type_cases(action_types) %}
    {% for action_type in action_types %}
        MAX(CASE WHEN action_type = '{{ action_type }}' THEN action_value ELSE NULL END) AS {{ action_type | replace('.', '_') | replace('like', 'like_action') }}{% if not loop.last %},{% endif %}
    {% endfor %}
{% endmacro %}

{% macro generate_action_type_cases_conversions(action_types) %}
    {% for action_type in action_types %}
        MAX(CASE WHEN action_type = '{{ action_type }}' THEN action_value ELSE NULL END) AS {{ action_type | replace('.', '_') | replace('-', '_') | replace(' ', '_') | lower }}{% if not loop.last %},{% endif %}
    {% endfor %}
{% endmacro %}