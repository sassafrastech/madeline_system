require 'rails_helper'

RSpec.describe Accounting::Quickbooks::TransactionFetcher, type: :model do
  subject { described_class.new(instance_double(Accounting::Quickbooks::Connection)) }

  let(:generic_service) { instance_double(Quickbooks::Service::Account, all: []) }
  before do
    allow(subject).to receive(:service).and_return(generic_service)
  end

  it 'should work when a nil query result is returned' do
    service = instance_double(Quickbooks::Service::Deposit, all: nil)
    allow(subject).to receive(:service).with('Deposit').and_return(service)
    expect { subject.fetch }.to_not raise_error
  end

  it 'should fetch all records for Deposit' do
    service = instance_double(Quickbooks::Service::Deposit, all: [])
    allow(subject).to receive(:service).with('Deposit').and_return(service)
    expect(service).to receive(:all)
    subject.fetch
  end

  it 'should fetch all records for JournalEntry' do
    service = instance_double(Quickbooks::Service::JournalEntry, all: [])
    allow(subject).to receive(:service).with('JournalEntry').and_return(service)
    expect(service).to receive(:all)
    subject.fetch
  end

  it 'should fetch all records for Purchase' do
    service = instance_double(Quickbooks::Service::Purchase, all: [])
    allow(subject).to receive(:service).with('Purchase').and_return(service)
    expect(service).to receive(:all)
    subject.fetch
  end

  it 'should create Accounting::Transaction record' do
    service = instance_double(Quickbooks::Service::Purchase, all: [instance_double(Quickbooks::Model::Purchase, id: 99)])
    allow(subject).to receive(:service).with('Purchase').and_return(service)

    expect{subject.fetch}.to change{Accounting::Transaction.all.count}.by(1)
  end
end