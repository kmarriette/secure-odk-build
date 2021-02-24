a) created the secureForm /server/model/secureFrom.rb
b) Need to create tables
-- create a secureForm  and secureFormData db
-- secure_form(form_id,secureform_id,user_id)
-- secure_form_data(secure_form_id,data)
c) Info
-- in the data column  in the form_data keeps each jsonArray called controls. ie {controls:[{},{},...]}. The elements of the controls array is JSON structure representing  a field attribute eg

{"name":"firstname",
"label":{"0":"First Name"},
"hint":{},
  "defaultValue":"",
  "readOnly":false,
  "required":true,
  "requiredText":{},
  "relevance":"",
  "constraint":"",
  "calculate":"",
  "length":false,"invalidText":{},
  "metadata":{},
  "type":"inputText"
}

-- implementation Options (a decision on whether to use same table ie the form_data table and possibly add two columns eg is_secured, sensitivity OR use a new table as desribe in b above. each way, there is need to create a migration(s)) 
a) possible to extend the  above attribute json with details regarding sensitivity eg
sensitivity:{whatever needs to be captured}



adding links

1. index.erb
2. data-ui.js
3. modals.js