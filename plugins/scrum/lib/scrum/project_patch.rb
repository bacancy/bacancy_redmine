require_dependency "project"

module Scrum
  module ProjectPatch
    def self.included(base)
      base.class_eval do

        belongs_to :product_backlog, :class_name => "Sprint"
        has_many :sprints, :dependent => :destroy, :order => "start_date ASC, name ASC",
                 :conditions => {:is_product_backlog => false}
        has_many :sprints_and_product_backlog, :class_name => "Sprint", :dependent => :destroy,
                 :order => "start_date ASC, name ASC"

        def last_sprint
          sprints.sort{|a, b| a.end_date <=> b.end_date}.last
        end

        def story_points_per_sprint
          i = self.sprints.length - 1
          sprints_count = 0
          story_points_per_sprint = 0.0
          while (sprints_count < Scrum::Setting.product_burndown_sprints and i >= 0)
            story_points = self.sprints[i].story_points
            if story_points > 0.0
              story_points_per_sprint += story_points
              sprints_count += 1
            end
            i -= 1
          end
          story_points_per_sprint /= sprints_count if story_points_per_sprint > 0 and sprints_count > 0
          story_points_per_sprint = 1 if story_points_per_sprint == 0
          story_points_per_sprint = story_points_per_sprint.round(2)
          return [story_points_per_sprint, sprints_count]
        end

      end
    end
  end
end
