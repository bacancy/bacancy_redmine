class ImportData < ActiveRecord::Base
  belongs_to :project
  belongs_to :member
  attr_accessible :member_name, :monthly_hours, :per_hour_salary, :salary, :project_id, :upload_for, :member_id

  def self.get_import_details(member_id)
    ImportData.where(member_id: member_id)   
  end
end
