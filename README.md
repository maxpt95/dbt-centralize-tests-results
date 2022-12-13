# DBT CENTRALIZE TEST RESULTS

This project contains a jinja2 macro for dbt that can be use to centralized all
tests results into a single table. Failed tests will be logged with their failures
details and passed tests will be logged with FAILURE statues false.

## REACH
The project contains only the needed macro and configuration (check dbt_project.yml)
for executing the centralization. 

## DBT_PROJECT.YML
The relevant configuration inside this file is:

```
on-run-end:
  - "{{ centralize_test_results(results, test) }}"  
  
```

THis will ensure that after each `dbt test` and `dbt run` the centralize_test_results
macro will be executed.
