namespace :milestone_notification do
  desc "Send milestone close reminder email to all the team members of a project before 3 days."
  task :close_reminder => :environment do
    @milestones = Milestone.where("date(effective_date) = ?", (Date.today + 3.days))
    puts "*************** START SENDING MILESTONE REMINDER *****************"
    @milestones.each{ |milestone| Mailer.milestone_close_reminder(milestone).deliver }
    puts "*************** STOP SENDING MILESTONE REMINDER *****************"
  end

end
