class ImportDataController < ApplicationController

  def new    
    @import_data = ImportData.new
    @projects = Project.select([:name, :id]).map {|e| [e.name, e.id] } 
  end

  def create     
    if request.post? && !params["import_data"]["file"].nil?      
      file = params["import_data"]["file"].tempfile.path      
      extension = params["import_data"]["file"].original_filename.split(".").last
      upload_for = DateTime.new(params["import_data"]["upload_for(1i)"].to_i, params["import_data"]["upload_for(2i)"].to_i)

      if extension.eql?("xls") || extension.eql?("xlsx")          
        xls = Roo::Spreadsheet.open(file, :extension => extension)
        @temp = save_data_for_roo(xls, params["import_data"]["project_id"], upload_for.utc)
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
        import = ImportData.new(:project_id => project_id, :member_id => row[0].to_i, :salary => AESCrypt.encrypt(row[1], "TeStSaLaRy"), :monthly_hours => row[2],:per_hour_salary => AESCrypt.encrypt(row[4], "TeStSaLaRy"), :member_name => row[3], :upload_for => upload_for)      
        if import.save        
        else
          error_records.push(row)
        end       
      end
    end 
    return error_records  
  end
end