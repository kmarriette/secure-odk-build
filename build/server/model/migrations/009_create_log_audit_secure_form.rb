Sequel.migration do
  up do
    create_table :update_audit_secure do
   	  foreign_key :secure_form_id, :secure_forms
      DateTime :timestamp, :null => false
      String :type, :size => 8
      integer :form_size
    end
  end

  down do
    drop_table :update_audit_secure
  end
end

