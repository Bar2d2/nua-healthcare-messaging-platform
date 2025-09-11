# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Messages::Presentation::ResponseService, type: :service do
  let(:controller) { double('controller') }
  let(:message) { double('message') }

  describe '.handle_creation_success' do
    before do
      allow(controller).to receive(:instance_variable_set)
      allow(controller).to receive(:flash).and_return({})
      allow(controller).to receive(:outbox_path).and_return('/outbox')
      allow(controller).to receive(:redirect_to)
      allow(controller).to receive(:respond_to).and_yield(controller)
      allow(controller).to receive(:turbo_stream).and_yield
      allow(controller).to receive(:html).and_yield
    end

    it 'sets instance variables and redirects to outbox' do
      described_class.handle_creation_success(controller, message, 'Success!')

      expect(controller).to have_received(:instance_variable_set).with(:@message, message)
      expect(controller.flash[:notice]).to eq('Success!')
      expect(controller).to have_received(:redirect_to).with('/outbox').twice
    end
  end

  describe '.handle_update_success' do
    before do
      allow(controller).to receive(:instance_variable_set)
      allow(controller).to receive(:redirect_to)
      allow(controller).to receive(:respond_to).and_yield(controller)
      allow(controller).to receive(:turbo_stream).and_yield
      allow(controller).to receive(:html).and_yield
      allow(I18n).to receive(:t).with('messages.notice.updated').and_return('Updated!')
    end

    it 'sets message and handles response formats' do
      described_class.handle_update_success(controller, message)

      expect(controller).to have_received(:instance_variable_set).with(:@message, message)
      expect(controller).to have_received(:redirect_to).with(message, notice: 'Updated!')
    end
  end

  describe '.handle_mark_all_read_response' do
    before do
      allow(controller).to receive(:render)
      allow(controller).to receive(:redirect_back)
      allow(controller).to receive(:inbox_path).and_return('/inbox')
      allow(controller).to receive(:respond_to).and_yield(controller)
      allow(controller).to receive(:turbo_stream).and_yield
      allow(controller).to receive(:json).and_yield
      allow(controller).to receive(:html).and_yield
      allow(I18n).to receive(:t).with('messages.notice.all_marked_read').and_return('All read!')
    end

    it 'handles all response formats correctly' do
      described_class.handle_mark_all_read_response(controller)

      expect(controller).to have_received(:render).with(:mark_all_read)
      expect(controller).to have_received(:render).with(json: { success: true, unread_count: 0 })
      expect(controller).to have_received(:redirect_back).with(
        fallback_location: '/inbox',
        notice: 'All read!'
      )
    end
  end

  describe '.handle_error_response' do
    before do
      allow(controller).to receive(:render)
      allow(controller).to receive(:respond_to).and_yield(controller)
      allow(controller).to receive(:turbo_stream).and_yield
      allow(controller).to receive(:html).and_yield
    end

    it 'renders error template with unprocessable_entity status' do
      described_class.handle_error_response(controller, :new)

      expect(controller).to have_received(:render).with(:new, status: :unprocessable_entity).twice
    end
  end
end
