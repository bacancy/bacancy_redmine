module ScrumHelper

  include ProjectsHelper

  def render_hours(hours, options = {})
    if hours.nil?
      ""
    else
      if hours.is_a?(Integer)
        text = ("%d" % hours) unless options[:ignore_zero] and hours == 0
      elsif hours.is_a?(Float)
        text = ("%g" % hours) unless options[:ignore_zero] and hours == 0.0
      else
        text = hours unless options[:ignore_zero] and (hours.blank? or (hours == "0"))
      end
      unless text.blank?
        text = "#{text} h"
        unless options[:link].nil?
          text = link_to(text, options[:link])
        end
        render :inline => "<span title=\"#{options[:title]}\">#{text}</span>"
      end
    end
  end

  def render_pbi_left_header(pbi)
    parts = []
    if Scrum::Setting.render_position_on_pbi
      parts << "#{l(:field_position)}: #{pbi.position}"
    end
    if Scrum::Setting.render_category_on_pbi and pbi.category
      parts << "#{l(:field_category)}: #{h(pbi.category.name)}"
    end
    if Scrum::Setting.render_version_on_pbi and pbi.fixed_version
      parts << "#{l(:field_fixed_version)}: #{link_to_version(pbi.fixed_version)}"
    end
    render :inline => parts.join(", ")
  end

  def render_pbi_right_header(pbi)
    parts = []
    if Scrum::Setting.render_author_on_pbi
      parts << authoring(pbi.created_on, pbi.author)
    end
    if Scrum::Setting.render_updated_on_pbi and pbi.created_on != pbi.updated_on
      parts << "#{l(:label_updated_time, time_tag(pbi.updated_on))}"
    end
    render :inline => parts.join(", ")
  end

end
