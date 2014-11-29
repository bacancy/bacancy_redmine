# encoding: UTF-8

# This plugin should be reloaded in development mode.
if (Rails.env == "development")
  ActiveSupport::Dependencies.autoload_once_paths.reject!{|x| x =~ /^#{Regexp.escape(File.dirname(__FILE__))}/}
end

Issue.send(:include, Scrum::IssuePatch)
IssueQuery.send(:include, Scrum::IssueQueryPatch)
IssuesController.send(:include, Scrum::IssuesControllerPatch)
IssueStatus.send(:include, Scrum::IssueStatusPatch)
Journal.send(:include, Scrum::JournalPatch)
Project.send(:include, Scrum::ProjectPatch)
ProjectsHelper.send(:include, Scrum::ProjectsHelperPatch)
Tracker.send(:include, Scrum::TrackerPatch)
User.send(:include, Scrum::UserPatch)

require_dependency "scrum/helper_hooks"
require_dependency "scrum/view_hooks"

Redmine::Plugin.register :scrum do
  name              "Scrum Redmine plugin"
  author            "Emilio González Montaña"
  description       "This plugin for Redmine allows to follow Scrum methodology with Redmine projects"
  version           "0.8.0"
  url               "https://redmine.ociotec.com/projects/redmine-plugin-scrum"
  author_url        "http://ociotec.com"
  requires_redmine  :version_or_higher => "2.3.0"

  project_module    :scrum do
    permission      :manage_sprints,
                    {:sprints => [:new, :create, :edit, :update, :destroy, :edit_effort, :update_effort]},
                    :require => :member
    permission      :view_sprint_board,
                    {:sprints => [:index, :show]}
    permission      :edit_sprint_board,
                    {:sprints => [:change_task_status],
                     :scrum => [:change_story_points, :change_pending_effort, :change_assigned_to,
                               :create_time_entry, :new_pbi, :create_pbi, :edit_pbi, :update_pbi,
                               :new_task, :create_task, :edit_task, :update_task]},
                    :require => :member
    permission      :view_sprint_burndown,
                    {:sprints => [:burndown_index, :burndown]}
    permission      :view_sprint_stats, {}
    permission      :view_sprint_stats_by_member, {}
    permission      :view_product_backlog,
                    {:product_backlog => [:index]}
    permission      :edit_product_backlog,
                    {:product_backlog => [:sort, :new_pbi, :create_pbi],
                     :scrum => [:edit_pbi, :update_pbi, :move_to_last_sprint, :move_to_product_backlog]},
                    :require => :member
    permission      :view_product_backlog_burndown,
                    {:product_backlog => [:burndown]}
    permission      :view_release_plan,
                    {:scrum => [:release_plan]}
  end

  menu              :project_menu, :scrum, {:controller => :sprints, :action => :index},
                    :caption => :label_scrum, :after => :activity, :param => :project_id

  settings          :default => {:create_journal_on_pbi_position_change => "0",
                                 :doer_color => "post-it-color-5",
                                 :pbi_status_ids => [],
                                 :pbi_tracker_ids => [],
                                 :reviewer_color => "post-it-color-3",
                                 :story_points_custom_field_id => nil,
                                 :task_status_ids => [],
                                 :task_tracker_ids => [],
                                 :verification_activity_ids => [],
                                 :inherit_pbi_attributes => "1",
                                 :render_position_on_pbi => "0",
                                 :render_category_on_pbi => "1",
                                 :render_version_on_pbi => "1",
                                 :render_author_on_pbi => "1",
                                 :render_updated_on_pbi => "0",
                                 :product_burndown_sprints => "4"},
                    :partial => "settings/scrum_settings"
end
