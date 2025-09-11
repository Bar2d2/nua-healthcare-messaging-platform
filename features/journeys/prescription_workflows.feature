# frozen_string_literal: true

Feature: Prescription Request Workflows
  As a patient
  I want to request lost prescriptions with payment processing
  So that I can get replacement prescriptions efficiently

  Background:
    Given the application is running
    And I have test users in the system

  @prescription @core @payment
  Scenario: Patient successfully requests prescription
    Given I am logged in as a patient
    When I navigate to prescriptions page
    And I request a lost prescription
    Then I should see a prescription request was created
    And the prescription should be in the system

  @prescription @navigation
  Scenario: Patient can navigate prescription interface
    Given I am logged in as a patient
    When I navigate to prescriptions page
    Then I should see the prescription request interface
    And I should see the request prescription button

  @prescription @modal
  Scenario: Patient can open prescription request modal
    Given I am logged in as a patient
    When I navigate to prescriptions page
    And I click the request prescription button
    Then I should see the prescription request modal
    And I should see the fee information
