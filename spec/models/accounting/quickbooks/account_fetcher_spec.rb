require 'rails_helper'

RSpec.describe Accounting::Quickbooks::AccountFetcher, type: :model do
  subject { described_class.new(instance_double(Accounting::Quickbooks::Connection)) }

  it 'should work when a nil query result is returned' do
    service = instance_double(Quickbooks::Service::Account, all: nil)
    allow(subject).to receive(:service).and_return(service)
    expect { subject.fetch }.to_not raise_error
  end

  it 'should fetch all records for Account' do
    service = instance_double(Quickbooks::Service::Account, all: [])
    allow(subject).to receive(:service).and_return(service)
    expect(service).to receive(:all)
    subject.fetch
  end
end
