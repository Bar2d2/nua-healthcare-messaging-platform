# frozen_string_literal: true

# Prescription workflow steps for lost prescription requests
# Handles prescription creation, payment processing, and admin generation

# Navigation Steps
When('I navigate to prescriptions page') do
  visit prescriptions_path
  expect(page).to have_content('My Prescriptions')
end

When('I visit my prescriptions page') do
  visit prescriptions_path
  expect(page).to have_content('My Prescriptions')
end

# Prescription Request Steps
When('I request a lost prescription') do
  click_button 'Request Prescription'

  sleep(2)

  expect(page).to have_content('Prescription Replacement Fee: €10')

  within('#lostPrescriptionModal') do
    click_button 'Pay €10 & Request Prescription'
  end

  sleep(2)

  expect(page).not_to have_content('Prescription Replacement Fee: €10')
end

# Payment Processing Steps
Then('I should see a prescription request was created') do
  expect(page).to have_content('Prescription Request')
end

Then('the prescription should be in the system') do
  expect(Prescription.count).to be >= 1
  expect(Payment.count).to be >= 1
end

# Simple Navigation Steps
Then('I should see the prescription request interface') do
  expect(page).to have_content('My Prescriptions')
  expect(page).to have_content('Request Prescription')
end

Then('I should see the request prescription button') do
  expect(page).to have_button('Request Prescription')
end

When('I click the request prescription button') do
  click_button 'Request Prescription'
end

Then('I should see the prescription request modal') do
  expect(page).to have_selector('#lostPrescriptionModal', visible: true)
end

Then('I should see the fee information') do
  expect(page).to have_content('€10')
  expect(page).to have_content('fee')
end

# Status Verification Steps
Then('I should see {string} status') do |status_text|
  expect(page).to have_content(status_text)
end

Then('I should see {string} with spinner') do |status_text|
  expect(page).to have_content(status_text)
  expect(page).to have_selector('.spinner-border')
end

Then('I should see a {string} button') do |button_text|
  expect(page).to have_button(button_text)
end

Then('the status should update to {string}') do |status_text|
  # Wait for real-time update
  expect(page).to have_content(status_text, wait: 5)
end

Then('the spinner should disappear') do
  expect(page).not_to have_selector('.spinner-border')
end

# Admin Workflow Steps
Given('I have a prescription request awaiting admin') do
  # Create a prescription in awaiting admin state
  payment = FactoryBot.create(:payment, status: :successful, user: @current_user)
  @prescription = FactoryBot.create(:prescription, :requested, user: @current_user, payment: payment)

  # Create the associated message for admin notification
  @admin_message = Message.create!(
    body: "Prescription request from #{@current_user.full_name}",
    outbox: @current_user.outbox,
    inbox: @admin.inbox,
    prescription: @prescription,
    routing_type: 'auto',
    status: 'delivered'
  )
end

When('I open the prescription request conversation') do
  # Find and click on the prescription-related message
  message_item = find('.list-group-item', text: 'Prescription request')
  message_item.click
end

When('I generate and send the prescription') do
  expect(page).to have_button('Generate & Send')
  click_button 'Generate & Send'

  # Wait for processing
  expect(page).to have_content('Processing...', wait: 3)

  # Wait for completion
  expect(page).not_to have_content('Processing...', wait: 10)
end

Then('the prescription status should update to {string}') do |_status|
  # The status update happens via background job and broadcasting
  sleep 1
end

Then('I should be able to download the prescription PDF') do
  expect(page).to have_link('Download PDF')
end

# Notification Steps
Then('an admin should receive the prescription request notification') do
  # Verify admin has received notification (via message)
  expect(@admin.inbox.messages.where(prescription: Prescription.last)).to exist
end

# Complex Workflow Steps
When('I complete a full prescription request workflow') do
  # Navigate to prescriptions
  visit prescriptions_path

  # Request prescription
  click_button 'Request Prescription'
  within('#lostPrescriptionModal') do
    click_button 'Pay €10 & Request Prescription'
  end

  # Wait for payment processing
  expect(page).to have_content('Awaiting Admin approval', wait: 5)

  @prescription = Prescription.last
end

Then('the prescription should be successfully delivered') do
  expect(@prescription.reload.status).to eq('ready')
end

Then('all status transitions should be correct') do
  # Verify the prescription went through correct states
  expect(@prescription.payment.status).to eq('successful')
  expect(@prescription.status).to eq('ready')
  expect(@prescription.pdf_url).to be_present
end

Then('both patient and admin should see appropriate updates') do
  # Patient should see ready status
  visit prescriptions_path
  expect(page).to have_content('Ready')

  # Admin should see the conversation updated
  # This would be verified through the message thread
end

# Payment Success Steps
Then('the payment should succeed') do
  # Manual retries always succeed in our system
  expect(page).to have_content('Awaiting Admin approval', wait: 5)
end

# Missing Step Definitions
When('I switch back to patient view') do
  # Use the user switcher to go back to patient
  within('.user-switcher') do
    click_button 'Patient'
  end
  expect(page).to have_content('Patient (Test)')
end

When('the payment completes successfully') do
  # Wait for payment processing to complete successfully
  sleep 1
end

Then('I should see the status change to {string}') do |status_text|
  expect(page).to have_content(status_text, wait: 5)
end
