namespace :work_time_log do
  desc 'Update Work Time Timer Entry on each 2 Minutes'
  task update_work_time_log: :environment do
      work_time_data = Worktimelog.where(:flag => 0, :finished => nil)
      if !work_time_data.empty?
        work_time_data.each do |temp_data|
          now = Time.now.in_time_zone(User.current.time_zone).getutc
          controller_obj = WorktimelogController.new
          spent_time =  controller_obj.time_to_sec(Time.at(now-Time.at(Time.parse(temp_data.started.to_s))).utc.strftime('%R:%S'))
          temp_data.total = spent_time
          temp_data.save
        end
      else
        p "Nothing to update"
      end
  end

  desc 'Send reminder mail every day on 6:00 PM'
  task send_reminder_mail: :environment do   
    users = User.where(status: User::STATUS_ACTIVE)
    if !users.empty?
      users.each do |user|
        have_issues = 0
        scrum_masters_array = []
        projects = user.projects.where(:status => Project::STATUS_ACTIVE)
        if !projects.empty? && !projects.nil?
          projects.each do |project|           
            issues = project.issues.where("assigned_to_id = ? AND (status_id = ? OR status_id = ?)", user.id, 1, 2)
            if !issues.empty?
              have_issues = have_issues + 1
              scrum_masters_array = project.scrum_masters                   
            end
          end
        end
        if have_issues > 0
          time_log = Worktimelog.where("user_id = ? AND DATE(finished) = ?", user.id, Date.today)
          if time_log.empty?
            scrum_masters_array = scrum_masters_array.push("chandresh.patel@bacancytechnology.com")
            scrum_masters_array = scrum_masters_array.push(user.mail)
            scrum_masters_array.uniq.each do |scrum_master|
              ReminderNotifier.send_reminder_email(user, scrum_master).deliver
            end
          end
        end
      end    
    end
  end
end