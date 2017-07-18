require 'rails_helper'

RSpec.describe Accounting::Quickbooks::Customer, type: :model do
  let(:qb_customer_id) { '91234' }
  let(:qb_new_customer) { instance_double(Quickbooks::Model::Customer, id: qb_customer_id) }

  subject { described_class.new(organization: organization, qb_connection: nil) }

  before do
    allow(subject).to receive(:service).and_return(service)
  end

  shared_examples_for 'qb customer' do
    context 'when qb customer does not exist' do
      let(:organization) { create(:organization, name: customer_name) }
      let(:service) { instance_double(Quickbooks::Service::Customer, create: qb_new_customer) }

      it 'creates Customer with a valid name' do
        expect(service).to receive(:create) do |arg|
          expect(arg.display_name).to eq created_customer_name
        end.and_return(qb_new_customer)

        subject.reference
      end

      it 'returns proper customer reference' do
        allow(service).to receive(:create).and_return(qb_new_customer)

        reference = subject.reference
        expect(reference.type).to eq 'Customer'
        expect(reference.entity_ref.value).to eq qb_customer_id
      end

      it 'saves qb_id to organization' do
        allow(service).to receive(:create).and_return(qb_new_customer)

        subject.reference
        expect(Organization.where(qb_id: qb_customer_id).count).to eq 1
      end
    end

    context 'when qb customer does exist' do
      let(:organization) { create(:organization, qb_id: qb_customer_id) }
      let(:service) { instance_double(Quickbooks::Service::Customer, create: nil) }

      it 'does not create a customer' do
        expect(service).not_to receive(:create)
        subject.reference
      end

      it 'returns proper customer reference' do
        allow(service).to receive(:create).and_return(qb_new_customer)

        reference = subject.reference
        expect(reference.type).to eq 'Customer'
        expect(reference.entity_ref.value).to eq qb_customer_id
      end
    end
  end

  context 'with valid name' do
    let(:customer_name) { 'A cooperative with a name' }
    let(:created_customer_name) { customer_name }

    it_behaves_like 'qb customer'
  end

  context 'with invalid name' do
    let(:customer_name) { 'A name:with a colon' }
    let(:created_customer_name) { 'A name_with a colon' }

    it_behaves_like 'qb customer'
  end

end