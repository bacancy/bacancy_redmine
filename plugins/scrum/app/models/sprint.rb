class Sprint < ActiveRecord::Base

  belongs_to :user
  belongs_to :project
  has_many :issues, :dependent => :destroy
  has_many :efforts, :class_name => "SprintEffort", :dependent => :destroy

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:project_id]
  validates_length_of :name, :maximum => 60
  validates_presence_of :name

  validates_presence_of :start_date

  validates_presence_of :end_date
  
  before_destroy :update_project_product_backlog

  def to_s
    name
  end

  def is_product_backlog?
    self.is_product_backlog
  end

  def pbis
    issues.all(:conditions => {:tracker_id => Scrum::Setting.pbi_tracker_ids,
                               :status_id => Scrum::Setting.pbi_status_ids},
               :order => "position ASC").select{|issue| issue.visible?}
  end

  def story_points
    pbis.collect{|pbi| pbi.story_points.to_f}.compact.sum
  end

  def tasks
    issues.all(:conditions => {:tracker_id => Scrum::Setting.task_tracker_ids}).select{|issue| issue.visible?}
  end

  def estimated_hours
    tasks.collect{|task| task.estimated_hours}.compact.sum
  end

  def time_entries
    tasks.collect{|task| task.time_entries}.flatten
  end

  def time_entries_by_activity
    results = {}
    total = 0.0
    if User.current.allowed_to?(:view_sprint_stats, project)
      time_entries.each do |time_entry|
        if time_entry.activity and time_entry.hours > 0.0
          if !results.key?(time_entry.activity_id)
            results[time_entry.activity_id] = {:activity => time_entry.activity, :total => 0.0}
          end
          results[time_entry.activity_id][:total] += time_entry.hours
          total += time_entry.hours
        end
      end
      results.values.each do |result|
        result[:percentage] = ((result[:total] * 100.0) / total).to_i
      end
    end
    return results.values, total
  end

  def time_entries_by_member
    results = {}
    total = 0.0
    if User.current.allowed_to?(:view_sprint_stats_by_member, project)
      time_entries.each do |time_entry|
        if time_entry.activity and time_entry.hours > 0.0
          if !results.key?(time_entry.user_id)
            results[time_entry.user_id] = {:member => time_entry.user, :total => 0.0}
          end
          results[time_entry.user_id][:total] += time_entry.hours
          total += time_entry.hours
        end
      end
      results.values.each do |result|
        result[:percentage] = ((result[:total] * 100.0) / total).to_i
      end
    end
    return results.values, total
  end

  def efforts_by_member
    results = {}
    total = 0.0
    if User.current.allowed_to?(:view_sprint_stats_by_member, project)
      efforts.each do |effort|
        if effort.user and effort.effort > 0.0
          if !results.key?(effort.user_id)
            results[effort.user_id] = {:member => effort.user, :total => 0.0}
          end
          results[effort.user_id][:total] += effort.effort
          total += effort.effort
        end
      end
      results.values.each do |result|
        result[:percentage] = ((result[:total] * 100.0) / total).to_i
      end
    end
    return results.values, total
  end

  def phs_by_pbi
    results = {}
    total = 0.0
    if User.current.allowed_to?(:view_sprint_stats, project)
      pbis.each do |pbi|
        pbi_story_points = pbi.story_points
        if pbi_story_points
          pbi_story_points = pbi_story_points.to_f
          if pbi_story_points > 0.0
            if !results.key?(pbi.tracker_id)
              results[pbi.tracker_id] = {:tracker => pbi.tracker, :total => 0.0}
            end
            results[pbi.tracker_id][:total] += pbi_story_points
            total += pbi_story_points
          end
        end
      end
      results.values.each do |result|
        result[:percentage] = ((result[:total] * 100.0) / total).to_i
      end
    end
    return results.values, total
  end

  def self.fields_for_order_statement(table = nil)
    table ||= table_name
    ["(CASE WHEN #{table}.end_date IS NULL THEN 1 ELSE 0 END)",
     "#{table}.end_date",
     "#{table}.name",
     "#{table}.id"]
  end

  scope :sorted, order(fields_for_order_statement)

private

  def update_project_product_backlog
    if is_product_backlog?
      project.product_backlog = nil
      project.save!
    end
  end

end
