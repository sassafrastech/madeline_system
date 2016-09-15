module AdminHelper
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

  def admin_custom_colors
    return @admin_custom_colors if @admin_custom_colors
    colors = {}
    colors[:banner_fg] = selected_division && selected_division.banner_fg_color || "white"
    colors[:banner_bg] = selected_division && selected_division.banner_bg_color || "#8C2426"
    colors[:accent_main] = selected_division && selected_division.accent_main_color || colors[:banner_bg]
    colors[:accent_fg_text] = selected_division && selected_division.accent_fg_color || colors[:banner_fg]

    # These two colors are derived from the user configurable ones using the Chroma gem.
    colors[:accent_darkened] = begin
      colors[:accent_main].paint.darken(5)
    rescue Chroma::Errors::UnrecognizedColor
      colors[:accent_main]
    end

    colors[:banner_fg_transp] = begin
      # Add alpha channel
      colors[:banner_fg].paint.tap { |c| c.rgb.a = 0.3 }.to_rgb
    rescue Chroma::Errors::UnrecognizedColor
      colors[:banner_fg]
    end

    @admin_custom_colors = colors
  end
