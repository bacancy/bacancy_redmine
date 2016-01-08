class ImportData < ActiveRecord::Base
  belongs_to :project
  belongs_to :member
  attr_accessible :member_name, :monthly_hours, :per_hour_salary, :salary, :project_id, :upload_for, :member_id
end
