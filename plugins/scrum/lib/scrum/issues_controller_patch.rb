require_dependency "issues_controller"

module Scrum
  module IssuesControllerPatch
    def self.included(base)
      base.class_eval do

        after_filter :save_pending_effort, :only => [:create, :update]
        before_filter :add_default_sprint, :only => [:new, :update_form]

      private

        def save_pending_effort
          if @issue.is_task? and @issue.id and params[:issue] and params[:issue][:pending_effort]
            @issue.pending_effort = params[:issue][:pending_effort]
          end
        end

        def add_default_sprint
          if @issue.id.nil?
            if @issue.is_task? and @project.last_sprint
              @issue.sprint = @project.last_sprint
            elsif @issue.is_pbi? and @project.product_backlog
              @issue.sprint = @project.product_backlog
            else
              @issue.sprint = nil
            end
          end
        end

      end
    end
  end
end
