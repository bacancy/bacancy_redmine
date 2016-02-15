# Update Work time log entry on each 2 minutes.
every 2.minutes do
  rake 'work_time_log:update_work_time_log '
end

# Send reminder mail every day on 6:00 PM.
every 1.day, :at => '6:00 pm' do
  rake 'work_time_log:send_reminder_mail '
end