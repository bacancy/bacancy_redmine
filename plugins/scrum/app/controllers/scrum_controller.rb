class ScrumController < ApplicationController

  menu_item :scrum

  before_filter :find_issue, :only => [:change_story_points, :change_pending_effort,
                                       :change_assigned_to, :create_time_entry,
                                       :edit_task, :update_task]
  before_filter :find_sprint, :only => [:new_pbi, :create_pbi]
  before_filter :find_pbi, :only => [:new_task, :create_task, :edit_pbi, :update_pbi,
                                     :move_to_last_sprint, :move_to_product_backlog]
  before_filter :find_project_by_project_id, :only => [:release_plan]
  before_filter :authorize, :except => [:new_pbi, :create_pbi, :new_task, :create_task]
  before_filter :authorize_add_issues, :only => [:new_pbi, :create_pbi, :new_task, :create_task]

  helper :scrum
  helper :timelog
  helper :custom_fields
  helper :projects

  def change_story_points
    begin
      @issue.story_points = params[:value]
      status = 200
    rescue
      status = 503
    end
    render :nothing => true, :status => status
  end

  def change_pending_effort
    @issue.pending_effort = params[:value]
    render :nothing => true, :status => 200
  end

  def change_assigned_to
    @issue.init_journal(User.current)
    @issue.assigned_to = params[:value].blank? ? nil : User.find(params[:value].to_i)
    @issue.save!
    render_task(@project, @issue, params)
  end

  def create_time_entry
    time_entry = TimeEntry.new(params[:time_entry])
    time_entry.project_id = @project.id
    time_entry.issue_id = @issue.id
    time_entry.user_id = params[:time_entry][:user_id]
    call_hook(:controller_timelog_edit_before_save, {:params => params, :time_entry => time_entry})
    time_entry.save!
    render_task(@project, @issue, params)
  end

  def new_pbi
    @pbi = Issue.new
    @pbi.project = @project
    @pbi.tracker = @project.trackers.find(params[:tracker_id])
    @pbi.author = User.current
    @pbi.sprint = @sprint
    @top = !(params[:top].nil?)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create_pbi
    begin
      @continue = !(params[:create_and_continue].nil?)
      @top = !(params[:top].nil?)
      @pbi = Issue.new
      @pbi.project = @project
      @pbi.author = User.current
      @pbi.tracker_id = params[:issue][:tracker_id]
      update_attributes(@pbi, params)
      if @top
        @pbi.set_on_top
        @pbi.save!
      end
      @pbi.sprint = @sprint
      @pbi.save!
    rescue Exception => @exception
      log.error("Exception: #{@exception.inspect}")
    end
    respond_to do |format|
      format.js
    end
  end

  def edit_pbi
    respond_to do |format|
      format.js
    end
  end

  def update_pbi
    begin
      @pbi.init_journal(User.current, params[:issue][:notes])
      update_attributes(@pbi, params)
      @pbi.save!
    rescue Exception => @exception
      log.error("Exception: #{@exception.inspect}")
    end
    respond_to do |format|
      format.js
    end
  end

  def move_to_last_sprint
    begin
      raise "The project hasn't defined any Sprint yet" unless @project.last_sprint
      @previous_sprint = @pbi.sprint
      @pbi.init_journal(User.current)
      @pbi.sprint = @project.last_sprint
      @pbi.save!
    rescue Exception => @exception
      log.error("Exception: #{@exception.inspect}")
    end
    respond_to do |format|
      format.js
    end
  end

  def move_to_product_backlog
    begin
      raise "The project hasn't defined the Product Backlog yet" unless @project.product_backlog
      @pbi.init_journal(User.current)
      @pbi.sprint = @project.product_backlog
      @pbi.save!
    rescue Exception => @exception
      log.error("Exception: #{@exception.inspect}")
    end
    respond_to do |format|
      format.js
    end
  end

  def new_task
    @task = Issue.new
    @task.project = @project
    @task.tracker = Tracker.find(params[:tracker_id])
    @task.parent = @pbi
    @task.author = User.current
    @task.sprint = @sprint
    if Scrum::Setting.inherit_pbi_attributes
      @task.inherit_from_issue(@pbi)
    end
    respond_to do |format|
      format.html
      format.js
    end
  rescue Exception => e
    log.error("Exception: #{e.inspect}")
    render_404
  end

  def create_task
    begin
      @continue = !(params[:create_and_continue].nil?)
      @task = Issue.new
      @task.project = @project
      @task.parent_issue_id = @pbi.id
      @task.author = User.current
      @task.sprint = @sprint
      @task.tracker_id = params[:issue][:tracker_id]
      update_attributes(@task, params)
      @task.save!
      @task.pending_effort = params[:issue][:pending_effort]
    rescue Exception => @exception
    end
    respond_to do |format|
      format.js
    end
  end

  def edit_task
    respond_to do |format|
      format.js
    end
  end

  def update_task
    begin
      @issue.init_journal(User.current, params[:issue][:notes])
      @old_status = @issue.status
      update_attributes(@issue, params)
      @issue.save!
      @issue.pending_effort = params[:issue][:pending_effort]
    rescue Exception => @exception
      log.error("Exception: #{@exception.inspect}")
    end
    respond_to do |format|
      format.js
    end
  end

  def release_plan
    @sprints = []
    @story_points_per_sprint, @sprints_count = @project.story_points_per_sprint
    @total_story_points = 0.0
    @pbis_with_estimation = 0
    @pbis_without_estimation = 0
    last_sprint = nil
    versions = {}
    if @project.product_backlog
      @project.product_backlog.pbis.each do |pbi|
        if pbi.story_points
          @pbis_with_estimation += 1
          story_points = pbi.story_points.to_f
          @total_story_points += story_points
          accumulated_story_points = 0.0
          begin
            if last_sprint && last_sprint[:story_points] + story_points > @story_points_per_sprint
              @sprints << last_sprint
              last_sprint = nil
            end
            if last_sprint.nil?
              last_sprint = {:pbis => [], :story_points => 0.0, :versions => []}
            end
            if story_points <= @story_points_per_sprint
              last_sprint[:pbis] << pbi
              last_sprint[:story_points] += accumulated_story_points + story_points
              if pbi.fixed_version
                versions[pbi.fixed_version.id] = {:version => pbi.fixed_version, :sprint => @sprints.count}
              end
            else
              accumulated_story_points += @story_points_per_sprint
            end
            story_points -= @story_points_per_sprint
          end while story_points > 0.0
        else
          @pbis_without_estimation += 1
        end
      end
      if last_sprint
        @sprints << last_sprint
      end
      versions.each_pair do |id, info|
        @sprints[info[:sprint]][:versions] << info[:version]
      end
    end
  end

private

  def render_task(project, task, params)
    render :partial => "post_its/sprint_board/task",
           :status => 200,
           :locals => {:project => project,
                       :task => task,
                       :pbi_status_id => params[:pbi_status_id],
                       :other_pbi_status_ids => params[:other_pbi_status_ids].split(","),
                       :task_id => params[:task_id],
                       :read_only => false}
  end

  def find_sprint
    @sprint = Sprint.find(params[:sprint_id])
    @project = @sprint.project
  rescue
    log.error("Sprint #{params[:sprint_id]} not found")
    render_404
  end

  def find_pbi
    @pbi = Issue.find(params[:pbi_id])
    @sprint = @pbi.sprint
    @project = @sprint.project
  rescue
    log.error("PBI #{params[:pbi_id]} not found")
    render_404
  end

  def authorize_add_issues
    if User.current.allowed_to?(:add_issues, @project)
      return true
    else
      render_403
      return false
    end
  end

  def update_attributes(issue, params)
    issue.status_id = params[:issue][:status_id]
    raise "New status is not allowed" unless issue.new_statuses_allowed_to.include?(issue.status)
    issue.assigned_to_id = params[:issue][:assigned_to_id]
    issue.subject = params[:issue][:subject]
    issue.priority_id = params[:issue][:priority_id]
    issue.estimated_hours = params[:issue][:estimated_hours]
    issue.description = params[:issue][:description]
    issue.category_id = params[:issue][:category_id] if issue.safe_attribute?(:category_id)
    issue.fixed_version_id = params[:issue][:fixed_version_id] if issue.safe_attribute?(:fixed_version_id)
    issue.start_date = params[:issue][:start_date] if issue.safe_attribute?(:start_date)
    issue.due_date = params[:issue][:due_date] if issue.safe_attribute?(:due_date)
    issue.custom_field_values = params[:issue][:custom_field_values] unless params[:issue][:custom_field_values].nil?
  end

end
