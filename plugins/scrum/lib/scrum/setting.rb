module Scrum
  class Setting

    ["create_journal_on_pbi_position_change", "inherit_pbi_attributes", "render_position_on_pbi",
      "render_category_on_pbi", "render_version_on_pbi", "render_author_on_pbi",
      "render_updated_on_pbi"].each do |setting|
      src = <<-END_SRC
      def self.#{setting}
        setting_or_default_boolean(:#{setting})
      end
      END_SRC
      class_eval src, __FILE__, __LINE__
    end

    ["doer_color", "reviewer_color"].each do |setting|
      src = <<-END_SRC
      def self.#{setting}
        setting_or_default(:#{setting})
      end
      END_SRC
      class_eval src, __FILE__, __LINE__
    end

    ["task_status_ids", "task_tracker_ids", "pbi_status_ids", "pbi_tracker_ids",
      "verification_activity_ids"].each do |setting|
      src = <<-END_SRC
      def self.#{setting}
        collect_ids(:#{setting})
      end
      END_SRC
      class_eval src, __FILE__, __LINE__
    end

    def self.story_points_custom_field_id
      ::Setting.plugin_scrum[:story_points_custom_field_id]
    end

    def self.task_tracker
      Tracker.all(task_tracker_ids)
    end

    def self.tracker_id_color(id)
      setting_or_default("tracker_#{id}_color")
    end

    def self.product_burndown_sprints
      setting_or_default_integer(:product_burndown_sprints, :min => 1)
    end

    def self.tracker_fields(tracker)
      collect("tracker_#{tracker}_fields")
    end

    def self.tracker_field?(tracker, field)
      tracker_fields(tracker).include?(field.to_s)
    end

    def self.tracker_custom_fields(tracker)
      collect_ids("tracker_#{tracker}_custom_fields")
    end

    def self.tracker_custom_field?(tracker, custom_field)
      tracker_custom_fields(tracker).include?(custom_field.id)
    end

  private

    def self.setting_or_default(setting)
      ::Setting.plugin_scrum[setting] ||
      Redmine::Plugin::registered_plugins[:scrum].settings[:default][setting]
    end

    def self.setting_or_default_boolean(setting)
      setting_or_default(setting) == "1"
    end

    def self.setting_or_default_integer(setting, options = {})
      value = setting_or_default(setting).to_i
      value = options[:min] if options[:min] and value < options[:min]
      value = options[:max] if options[:max] and value > options[:max]
      value
    end

    def self.collect_ids(setting)
      (::Setting.plugin_scrum[setting] || []).collect{|value| value.to_i}
    end

    def self.collect(setting)
      (::Setting.plugin_scrum[setting] || [])
    end

  end
end
