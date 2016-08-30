module AdminHelper
  DEFAULT_BANNER_FG_COLOR = 'white'
  DEFAULT_BANNER_BG_COLOR = 'black'

  def division_select_options
    [[I18n.t("divisions.shared.all"), nil]].concat(
      current_user.accessible_divisions.reject(&:root?).map{ |d| [d.name, d.id] })
  end

  def authorized_form_field(simple_form: nil, model: nil, field_name: nil, choices: nil,
    include_blank_choice: true, classes: '')
    model_field = model.send(field_name)
    if model_field
      policy = "#{model_field.class.name}Policy".constantize.new(current_user, model_field)
      link_path = url_for([:admin, model_field])
    end

    render partial: 'admin/common/authorized_form_field', locals: {
      f: simple_form,
      model_field: model_field,
      field_name: field_name,
      id_field_name: "#{field_name}_id",
      link_path: link_path,
      choices: choices,
      include_blank_choice: include_blank_choice,
      may_show_link: model_field && policy.show?,
      # Beware, if the 'may_edit' logic changes and might be false even with a non-nil model_field,
      # then the paratial code will also need updating to make nil safe.
      may_edit: !model_field || policy.show?,
      classes: classes
    }
  end

  def admin_banner_fg_color
    selected_division && selected_division.banner_fg_color || DEFAULT_BANNER_FG_COLOR
  end

  def admin_banner_bg_color
    selected_division && selected_division.banner_bg_color || DEFAULT_BANNER_BG_COLOR
  end
end
