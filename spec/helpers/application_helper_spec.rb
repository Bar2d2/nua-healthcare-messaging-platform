# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe 'helper methods' do
    it 'can be included in view specs' do
      expect(helper).to be_a(ActionView::Base)
    end
  end
end
