
shared_examples_for 'custom_field_set_addable' do
  let(:model_instance) { create(described_class.to_s.underscore) }


  it 'should set and get custom values' do
    create(:custom_field_set, :generic_fields, internal_name: described_class.name)
    model_instance.update_custom_value('a_string', 'how_now')
    model_instance.update_custom_value('a_number', 7)
    model_instance.update_custom_value('a_boolean', true)
    fetched = described_class.find(model_instance.id)
    # puts("fetched custom data: #{fetched.custom_data}")
    expect(fetched.custom_value('a_string')).to eq 'how_now'
    expect(fetched.custom_value('a_number')).to eq 7
    expect(fetched.custom_value('a_boolean')).to be true
  end

  it 'can filter by custom value' do
    root_division
    create(:custom_field_set, :generic_fields, internal_name: described_class.name)
    model_instance.update_custom_value('a_boolean', true)
    expect(described_class.where_custom_value('a_boolean', 'true').count).to be 1
    expect(described_class.where_custom_value('a_boolean', 'false').count).to be 0
    model_instance.update_custom_value('a_boolean', false)
    expect(described_class.where_custom_value('a_boolean', 'true').count).to be 0
    expect(described_class.where_custom_value('a_boolean', 'false').count).to be 1
  end

  # beware this code assumes described model has a directly assignable division
  # if that assumption becomes invalid, then this test needs to be further adapted
  it 'should handle inherited custom field sets' do
    sub_division = create(:division, parent: root_division, internal_name: 'sub')
    field_set = create(:custom_field_set, division: root_division, internal_name: described_class.name)
    create(:custom_field, custom_field_set: field_set, internal_name: 'root_string', data_type: 'string')
    model_instance = create(described_class.to_s.underscore, division: sub_division)
    model_instance.update_custom_value('root_string', 'root_value')
    fetched = described_class.find(model_instance.id)
    expect(fetched.custom_value('root_string')).to eq 'root_value'

    sub_field_set = create(:custom_field_set, division: sub_division, internal_name: described_class.name)
    create(:custom_field, custom_field_set: sub_field_set, internal_name: 'sub_string', data_type: 'string')
    expect { model_instance.custom_value('root_string') }.to raise_error(RuntimeError)

    model_instance.update_custom_value('sub_string', 'sub_value')
    fetched = described_class.find(model_instance.id)
    expect(fetched.custom_value('sub_string')).to eq 'sub_value'
  end



end
