# encoding: UTF-8

require 'json'

require './server/model/connection_manager'
require './server/lib/extensions'

class SecureForm
 def self.find_by_plain_form_id(form_id)
    data = SecureForm.table.filter( :form_id => form_id.to_i,:deleted_at => nil ).first
    return nil if data.blank?
    return (SecureForm.new data)
  end


  def self.find(uid)
    data = SecureForm.table.filter( :uid => uid.to_s, :deleted_at => nil ).first

    return nil if data.blank?
    return (SecureForm.new data)
  end

  def self.find_by_user(user)
    return SecureForm.table.filter( :user_id => user.id, :deleted_at => nil ).map{ |data| SecureForm.new(data) } || []
  end
 
  
  # Class
  def data(summary = false)
  	form = Form.find_by_id(self.form_id)
    result = {
      :id => self.uid,
      :form_id => self.form_id,
      :title => (form.title unless form.blank?)
    }
    unless summary
      blob = self.blob
      result.merge!({
        :controls => blob[:controls],
        :metadata => blob[:metadata],
        :sdf=>blob[:sdf],
        :isNewSecureForm=>blob[:isNewSecureForm],
        :owner => self.owner.data(true)
      })
    end
    return result
  end

  def self.create(data, owner)
  	
    begin
      uid = (String.random_chars 6)
    end while !SecureForm.find(uid).blank?

    secureForm = nil
    
    begin
      ConnectionManager.db.transaction do
      	 puts "data " +data.to_s
      	 puts "owner Id " + owner.id.to_s
      	 puts "form Id " + data[:form_id].to_s
        SecureForm.table.insert({ :uid => uid, :form_id =>data[:form_id].to_i, :user_id => owner.id.to_i })
 		
        secureForm = SecureForm.find(uid)
        
        #data=classify_static(data)
       
        SecureForm.blob_table.insert({
          :secure_form_id => secureForm.id,
          :data => { :controls => data[:controls], :metadata => data[:metadata],:isNewSecureForm=>1,:sdf=>data[:sdf] }.to_json
        })
      end
    rescue Sequel::DatabaseError
    	 p $!.message
      return nil
    end

    secureForm.log_audit!('create')
    return secureForm
  end

  def update(data)
  	form_id= data[:form_id]
  	
  	#data=classify_static(data)
  	
    self.form_id = form_id.to_i unless form_id.nil?
    self.blob = { :controls => data[:controls], :metadata => data[:metadata],:isNewSecureForm=>1,:sens=>data[:sens] }
  end

  def delete!
    # we soft delete just in case.
    @data[:deleted_at] = DateTime.now
    self.save
  end

  def log_audit!(type)
    # TODO: for some reason if we don't join this thread the database statement
    # never runs and the thread just hangs. right now we're fast enough (<60ms)
    # that it isn't a big perf hit to run this in-line, but it'd be nice to be
    # able to background it in the future sometime.
    Thread.new{ SecureForm.audit_table.insert({ :secure_form_id => self.id, :timestamp => DateTime.now, :type => type }) }.join
  end

  def save
    ConnectionManager.db.transaction do
      row.update(@data)
      blob_row.update({ :data => @blob.to_json }) unless @blob.nil?
    end
    self.log_audit!('update')
  end

  def ==(other)
    return false unless other.is_a? SecureForm
    return other.id == self.id
  end
  
  # Fields
  def id
    return @data[:id]
  end

  def uid
    return @data[:uid]
  end

  def form_id
    return @data[:form_id]
  end
  def form_id=(form_id)
    @data[:form_id] = form_id
  end

  def owner
    return User.find_by_id @data[:user_id]
  end

  def blob
    blob = SecureForm.blob_table.filter( :secure_form_id => self.id ).first
    result = JSON.parse(blob[:data] || "", :symbolize_names => true ) unless blob.blank?
  end
  def blob=(blob)
    @blob = blob
  end
  
private
  def initialize(data)
    @data = data
  end

  def self.table
    return ConnectionManager.db[:secure_forms]
  end

  def self.blob_table
    return ConnectionManager.db[:secure_form_data]
  end

  def self.audit_table
    return ConnectionManager.db[:update_audit_secure]
  end

  def row
    return SecureForm.table.filter( :uid => self.uid, :deleted_at => nil )
  end

  def blob_row
    return SecureForm.blob_table.filter( :secure_form_id => self.id )
  end
  
 
end
