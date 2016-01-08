class ImportDataController < ApplicationController

  def new    
    @import_data = ImportData.new
    @projects = Project.select([:name, :id]).map {|e| [e.name, e.id] } 
  end

  def create
    # Code for fetching data
    # if request.post?
    #   project_id = params["import_data"]["project_id"]
    #   project_data = Project.joins(:members).where(:id => project_id).only(:where).pluck(members.user_id)
    #   Member.joins(:time_entries, :member_roles, :import_data, :roles).where(:project_id => project_id).sum(time_entries.hours * import_data.per_hour_salary).group(roles.name)
    #   raise project_data.inspect
    # end
    
    if request.post? && !params["import_data"]["file"].nil?      
      file = params["import_data"]["file"].tempfile.path      
      extension = params["import_data"]["file"].original_filename.split(".").last
      upload_for = Date.new(params["import_data"]["upload_for(1i)"].to_i,params["import_data"]["upload_for(2i)"].to_i).strftime("%Y-%m-%d") 
      if extension.eql?("xls")              
        xls = Roo::Spreadsheet.open(file, extension: :xls)
        @temp = save_data_for_roo(xls, params["import_data"]["project_id"], upload_for)
        check_temp_data(@temp)       
      elsif extension.eql?("xlsx")
        xls = Roo::Spreadsheet.open(file, extension: :xlsx)
        @temp = save_data_for_roo(xls, params["import_data"]["project_id"], upload_for)
        check_temp_data(@temp)    
      else
        flash[:error] = l(:excel_file_extension_error)
        redirect_to :back
      end
    else
      flash[:error] = l(:excel_no_file_choose_error)
      redirect_to :back
    end
  end

  # Cheeck if data saves sucessfullt or not
  def check_temp_data(temp_data)
    if temp_data.empty?        
      flash[:notice] = l(:excel_file_import_sucess)
      redirect_to :back
    else
      flash[:warning] = l(:excel_file_recorde_save_error)
      redirect_to :back
    end
  end

  private
  # Save data of uploaded file
  def save_data_for_roo(sheet,project_id, upload_for) 
    tmp = 0
    error_records = []
    sheet.each do |row|
      if tmp == 0    
         tmp = tmp + 1
      else   
        import = ImportData.new(:project_id => project_id, :member_id => row[0].to_i, :salary => row[1], :monthly_hours => row[2],:per_hour_salary =>row[4], :member_name => row[3], :upload_for => upload_for)      
        if import.save          
        else
          error_records.push(row)
        end       
      end
    end 
    return error_records  
  end
end