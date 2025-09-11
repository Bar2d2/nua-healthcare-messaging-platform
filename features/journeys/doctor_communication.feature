# frozen_string_literal: true

Feature: Doctor Communication Journey
  As a doctor
  I want to communicate with patients
  So that I can provide medical care and guidance

  Background:
    Given the application is running
    And I have test users in the system

  @doctor @core
  Scenario: Doctor views patient messages
    Given I am logged in as a doctor
    When I visit my inbox
    Then I should see my inbox page

  @doctor @core @reply
  Scenario: Doctor replies to patient message
    Given I am logged in as a doctor
    And I have received a message from a patient
    When I visit my inbox
    And I open the message
    And I reply to the message with "Thank you for your message"
    Then I should see message sent successfully
    And the reply should appear in my outbox
