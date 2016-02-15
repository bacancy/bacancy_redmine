class DailyStatusReportController < ApplicationController
  def index
   @user_list = User.active.order(:firstname).map{|m| [[m.firstname.capitalize, m.lastname.capitalize].join(" "), m.id] if m.present?}    
   @user_list.unshift(["Select Developer", 00])
   @date_data = Date.today
   @status_data = {}
     if params.has_key?(:daily_status)
        @developer_id = params['daily_status']['developer_id'].to_i
        @report_type = params['daily_status']['report_type']
        day = params['daily_status']['filter_for(3i)'].to_i
        month = params['daily_status']['filter_for(2i)'].to_i
        year = params['daily_status']['filter_for(1i)'].to_i
        @date_data = Date.new(year,month,day)
        if @developer_id != 0 && day != 0 && month != 0 && year != 0
          date_data = DateTime.new(year,month,day)    
          @tmp_data = {}      
          if @report_type == "M"      
            # Monthly Report
            Worktimelog.where(user_id: @developer_id).where(started: date_data.beginning_of_month..date_data.end_of_month).includes(:issue, :project).group_by {|m| m.started.beginning_of_day }.each{|k, v| @status_data.merge!(k => v.group_by{|d| d.issue.project.name}.map{|k2,v2| [k2 => v2.map{|k3, v3=k3.issue| [k3.total, v3.subject, k3.issue_id, v3.status.name, v3.project.name]}.group_by{|d| d[2]}.map{|k4,v4| [v4[0][1],v4[0][3],v4[0][2], v4.map{|h| h[0]}.inject{|sum,a| sum + a}]}]})}
          else        
            # Daily Report
            Worktimelog.where(user_id: @developer_id).where(started: date_data.beginning_of_day..date_data.end_of_day).includes(:issue, :project).group_by {|m| p m.issue.project.name }.each{|k, v| @status_data.merge!(k => v.map{|k1, i1= k1.issue| [k1.total, i1.subject, k1.issue_id, i1.status.name, i1.project.name]}.group_by{|d| d[2]}.map{|k2,v2| [v2[0][1],v2[0][3],v2[0][2], v2.map{|h| h[0]}.inject{|sum,a| sum + a}]})}          
          end
        else
          flash.now[:error] = l(:daily_status_developer_field_error)
        end
     end
  end
end