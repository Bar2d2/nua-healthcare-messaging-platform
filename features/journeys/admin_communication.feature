# frozen_string_literal: true

Feature: Admin Communication Journey
  As an admin
  I want to handle administrative communications and patient messages
  So that I can provide support when doctors are unavailable

  Background:
    Given the application is running
    And I have test users in the system

  @admin @core
  Scenario: Admin views administrative messages
    Given I am logged in as an admin
    When I visit my inbox
    Then I should see my inbox page
    When I visit my outbox
    Then I should see my outbox page

  @admin @core @routing
  Scenario: Admin receives patient message (when no doctors available)
    Given I am logged in as a patient
    And no doctors are available in the system
    When I visit the new message page
    And I fill in and submit the message form
    Then I should see a success message
    And the message should be routed to an admin

  @admin @core @reply
  Scenario: Admin replies to patient message
    Given I am logged in as an admin
    And I have received a message from a patient
    When I visit my inbox
    And I open the message
    And I reply to the message with "Thank you for contacting us"
    Then I should see message sent successfully
    And the reply should appear in my outbox

  @admin @routing @verification
  Scenario: Patient messages route to admin when no doctors available
    Given I am logged in as a patient
    And no doctors are available in the system
    When I visit the new message page
    And I fill in and submit the message form
    Then I should see a success message
    And the message should be routed to an admin

  @admin @ui @verification
  Scenario: Admin can view routed messages in UI
    Given I am logged in as a patient
    And no doctors are available in the system
    When I visit the new message page
    And I fill in and submit the message form
    Then I should see a success message
    And the message should be routed to an admin
    When I switch to admin view
    And I visit my inbox
    Then I should see the patient message in admin inbox
