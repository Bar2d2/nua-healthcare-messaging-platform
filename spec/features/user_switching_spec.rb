# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'User Switching', type: :feature, js: false do
  let(:patient) { create(:user, :patient) }
  let(:doctor) { create(:user, :doctor) }
  let(:admin) { create(:user, :admin) }

  before do
    patient
    doctor
    admin
  end

  context 'in test environment' do
    scenario 'displays user switcher in navigation' do
      visit root_path

      expect(page).to have_content('Patient')
      expect(page).to have_selector('.dropdown-toggle')
      expect(page).to have_content('Demo Mode')
    end

    scenario 'allows switching between user roles' do
      visit root_path

      # Start as patient
      expect(page).to have_content('Patient')

      # Open dropdown and switch to doctor
      find('.dropdown-toggle').click
      click_button '🩺 Doctor'

      expect(page).to have_content('Switched to Doctor')
      expect(page).to have_content('Doctor')

      # Open dropdown and switch to admin
      find('.dropdown-toggle').click
      click_button '⚙️ Admin'

      expect(page).to have_content('Switched to Admin')
      expect(page).to have_content('Admin')

      # Open dropdown and switch back to patient
      find('.dropdown-toggle').click
      click_button '👩‍⚕️ Patient'

      expect(page).to have_content('Switched to Patient')
      expect(page).to have_content('Patient')
    end

    scenario 'persists user choice across page navigation' do
      visit root_path

      # Switch to doctor
      find('.dropdown-toggle').click
      click_button '🩺 Doctor'

      # Navigate to different pages
      visit inbox_path
      expect(page).to have_content('Doctor')

      visit outbox_path
      expect(page).to have_content('Doctor')

      visit new_message_path
      expect(page).to have_content('Doctor')
    end

    scenario 'allows resetting to default user' do
      visit root_path

      # Switch to admin
      find('.dropdown-toggle').click
      click_button '⚙️ Admin'
      expect(page).to have_content('Admin')

      # Reset to default
      find('.dropdown-toggle').click
      click_button '🔄 Reset to Default'

      expect(page).to have_content('Returned to default user')
      expect(page).to have_content('Patient')
    end
  end
end
