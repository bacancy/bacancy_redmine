class ReminderNotifier < ActionMailer::Base
  default from: "noreply@leangile.com"

  def send_reminder_email(user, scrum_master) 
  	@user = user
  	mail( :to => scrum_master, :subject => 'Reminder for work')  	
  end
end
