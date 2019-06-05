class PercentageInput < SimpleForm::Inputs::NumericInput
  def input(wrapper_options = nil)
    # copied from source NumericInput (https://github.com/plataformatec/simple_form/blob/master/lib/simple_form/inputs/numeric_input.rb)
    input_html_classes.unshift("numeric")
    if html5?
      input_html_options[:type] ||= "number"
      input_html_options[:step] ||= integer? ? 1 : "any"
    end

    merged_input_options = merge_wrapper_options(input_html_options, wrapper_options)
    # end copied from source
    template.content_tag(:div, class: 'percentage-input form-element') do
      template.concat @builder.text_field(attribute_name, merged_input_options)
      template.concat span_percentage
    end
  end

  def span_percentage
    template.content_tag(:span, class: 'percentage') do
      template.concat "%"
    end
  end
end
