select 1 as `one`
    , date("{{ today_dash }}") as today
    , "{{ yesterday_slash }}" as yesterday
    , "{{ name }}" as name
    , "${source_project_id }" as project_id
from `${source_project_id }.ae_demo.test`