class ProjectCostsController < ApplicationController
  
  def fetch_developer_list
    project_id = params[:id].to_i   
    @developer_data = Member.includes(:user).where(project_id: project_id).map{|m, u=m.user| [[u.firstname.capitalize, u.lastname.capitalize].join(" "), u.id, m.id] if u.present?}    
  end  

  def index
    return render_403 unless User.current.admin?
    @demo_data
    @projects = Project.select([:name, :id]).order(:name).map {|e| [e.name, e.id] }     
    if params.has_key?(:project_cost)       
      project_id = params['project_cost']['project_id']      
      @project_data = Project.find(project_id)
      member_data = get_member_data(params['project_cost'],project_id.to_i, params['project_cost']['member_id'].to_i)
      user_data = member_data.pluck(:user_id) 
      time_data = {}          
      get_time_data(user_data, project_id).group_by { |m| m.started.beginning_of_month }.each{|k,v| time_data.merge!( k => v.collect{|x| [x.user_id, x.total]}.group_by{|a| a[0]}.map{|k1, v1| {k1 => v1.map{|h| h[1]}.inject{|sum,a| sum + a} } })}
      upload_for_details = check_date_params(params["project_cost"]["filter_for(1i)"].to_i, params["project_cost"]["filter_for(2i)"].to_i)
      if !upload_for_details
        import_data = get_import_data(member_data.pluck(:id)).includes(:member).map{|m, u=m.member| [m.member_id, m.per_hour_salary, m.upload_for, u.user_id] }.group_by { |u| u[2].beginning_of_month }
      else
        import_data = get_import_data(member_data.pluck(:id)).where(:upload_for => upload_for_details).includes(:member).map{|m, u=m.member| [m.member_id, m.per_hour_salary, m.upload_for, u.user_id] }.group_by { |u| u[2].beginning_of_month  }
      end
      @month_hash_data = calculate_monthly_costing(import_data, time_data)
    end             
  end

  # Get member data
  def get_member_data(param, project_id, member_id)
    if param.has_key?(:member_id) && member_id != 00
        member_data = Member.where(id: member_id) 
      else
        member_data = get_member_data_by_project_id(project_id) 
      end 
  end

  # Get member data based on project id
  def get_member_data_by_project_id(project_id)
    Member.get_member_details_by_project_id(project_id)    
  end

  # Get time data based on project_id and user_details
  def get_time_data(user_data, project_id)
   # data = TimeEntry.where(user_id: user_data, project_id: project_id).select([:hours,:user_id,:spent_on])
    Worktimelog.joins("LEFT JOIN #{Issue.table_name} ON #{Worktimelog.table_name}.issue_id = #{Issue.table_name}.id").where(user_id: user_data).where("#{Issue.table_name}.project_id = #{project_id}").select("#{Worktimelog.table_name}.total, #{Worktimelog.table_name}.user_id, #{Worktimelog.table_name}.started")   
  end

  # Get import data based on member_id
  def get_import_data(member_id)
    ImportData.get_import_details(member_id)    
  end

  # Check Date and it's format
  def check_date_params(month, year)
    if month != 0 && year != 0
      DateTime.new(params["project_cost"]["filter_for(1i)"].to_i, params["project_cost"]["filter_for(2i)"].to_i).strftime("%Y-%m-%d 05:30:00")   
    else
      return false 
    end     
  end

  # Check role conditions and return role
  def check_role(mem_data)
    if mem_data.size > 1           
      if mem_data.include?(3) &&  mem_data.include?(4) || (mem_data.include?(11) &&  mem_data.include?(3))
        role = 4
      elsif (mem_data.include?(11) &&  mem_data.include?(4)) 
        role = 11
      else
        role = mem_data.first
      end              
    else
      role = mem_data.first
    end
    return role
  end

  # Calculate Month wise costing and return it's array
  def calculate_monthly_costing(import_data, time_data)
    month_hash_data = {}
    import_data.each do |k,v| 
      developer_array = []
      scrum_mastrer_array = []
      designer_array = []
      tester_array = []
      other_array = []  
      if !time_data[k].nil?         
        v.each do |k1|
          mem_data = MemberRole.where(member_id:  k1[0]).pluck(:role_id) 
          role = check_role(mem_data)
                   
          # role wise calculation
          member_hash_data = {}
            time_data[k].each do |tmp|
              if !tmp[k1[3]].nil?
                case role
                when 3
                  scrum_mastrer_array.push([(tmp[k1[3]]/3600.00),AESCrypt.decrypt(k1[1], "TeStSaLaRy").to_f])
                when 4
                  developer_array.push([(tmp[k1[3]]/3600.00),AESCrypt.decrypt(k1[1], "TeStSaLaRy").to_f])
                when 11
                  designer_array.push([(tmp[k1[3]]/3600.00),AESCrypt.decrypt(k1[1], "TeStSaLaRy").to_f])                    
                when 5
                  tester_array.push([(tmp[k1[3]]/3600.00),AESCrypt.decrypt(k1[1], "TeStSaLaRy").to_f])                    
                else
                  other_array.push([(tmp[k1[3]]/3600.00),AESCrypt.decrypt(k1[1], "TeStSaLaRy").to_f])                    
                end
              end
            end                            
        end           
        tmp_arr = [{'developer' => developer_array}, {'scrum_master' => scrum_mastrer_array}, {'designer' => designer_array}, {'tester' =>tester_array}, {'other' => other_array}]
        month_hash_data.merge!(k => tmp_arr)            
      end
    end
    return month_hash_data
  end
end
# Single Query   
# test_data = Member.joins("LEFT JOIN #{TimeEntry.table_name} ON #{Member.table_name}.project_id = #{TimeEntry.table_name}.project_id AND #{Member.table_name}.user_id = #{TimeEntry.table_name}.user_id " +
#                         "LEFT JOIN #{MemberRole.table_name} ON #{Member.table_name}.id = #{MemberRole.table_name}.member_id " +
#                         "LEFT JOIN #{ImportData.table_name} ON #{Member.table_name}.id = #{ImportData.table_name}.member_id " +
#                         "LEFT JOIN #{Role.table_name} ON #{MemberRole.table_name}.role_id = #{Role.table_name}.id ").select("#{MemberRole.table_name}.member_id").where("#{Member.table_name}.project_id = #{project_id}").group("#{Role.table_name}.name").sum("#{TimeEntry.table_name}.hours * #{ImportData.table_name}.per_hour_salary")
# raise test_data.inspect  