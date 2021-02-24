Sequel.migration do
  up do
    create_table :secure_forms do
      primary_key :id
      String :uid, :null => false, :unique => true
      foreign_key :form_id, :forms, :null => false
      foreign_key :user_id, :users
    end

    create_table :secure_form_data do
      foreign_key :secure_form_id, :secure_forms, :null => false
      String :data, :text => true
      index :secure_form_id
    end
  end

  down do
    drop_table :secure_forms
    drop_table :secure_form_data
  end
end
