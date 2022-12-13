{% macro centralize_test_results(results, dataset) %}

  {%- set test_results = [] -%}
  {%- for result in results -%}
    {%- if result.node.resource_type == 'test' and result.status != 'skipped' and (
          result.node.config.get('store_failures') or flags.STORE_FAILURES
      )
    -%}
      {%- do test_results.append(result) -%}
    {%- endif -%}
  {%- endfor -%}
  
  {%- set central_tbl -%} {{ target.schema }}_tests.test_central {%- endset -%}
  
  {{ log("Centralizing test failures in " + central_tbl, info = true) if execute }}


  
  {% for result in test_results %}

    {# if failure count > 0 thte test failed #}
    {% call statement('fail_count', fetch_result=True) %}
      SELECT COUNT(*) FROM {{ result.node.relation_name }};
    {% endcall %}

    {% set fail_count = load_result('fail_count')['data'][0][0] %} 
    
    INSERT INTO {{ central_tbl }} 
      {# Store failures #}
      {% if fail_count > 0 %}
        WITH TEST_FAILURES AS (
            SELECT
              TO_JSON_STRING(
                (SELECT AS STRUCT * FROM UNNEST([TEST]))
              ) AS FAILURES
            FROM {{ result.node.relation_name }} TEST
        )

        SELECT
          '{{ result.node.name }}' as TEST_NAME,
          TRUE AS FAILED,
          ARRAY_AGG( TEST_FAILURES.FAILURES) AS TEST_FAILURES,
          CURRENT_TIMESTAMP() AS TEST_DATE  
        FROM TEST_FAILURES
        GROUP BY
          TEST_NAME,
          TEST_DATE;

      {% else %}
        {# Store succesful tests #}
        SELECT
          '{{ result.node.name }}' as TEST_NAME,
          FALSE AS FAILED,
          [] AS TEST_FAILURES,
          CURRENT_TIMESTAMP() AS TEST_DATE;
   
      {% endif %}
        {# Drop individual test tables#}
        DROP TABLE {{ result.node.relation_name }};
  
  {% endfor %}

{% endmacro %}