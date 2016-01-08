class ImportDatas < ActiveRecord::Base
  belongs_to :project
  belongs_to :member
  attr_accessible :member_name, :monthly_hours, :per_hour_salary, :salary
end
