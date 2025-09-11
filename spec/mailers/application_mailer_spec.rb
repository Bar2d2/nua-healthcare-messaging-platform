# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationMailer, type: :mailer do
  it 'inherits from ActionMailer::Base' do
    expect(described_class).to be < ActionMailer::Base
  end

  it 'has default from address' do
    expect(described_class.default[:from]).to be_present
  end
end
