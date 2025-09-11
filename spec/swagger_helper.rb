# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.openapi_root = Rails.root.join('swagger').to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:swaggerize' rake task, the complete Swagger will
  # be generated at the provided relative path under openapi_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a openapi_spec tag to the
  # the root example_group in your specs, e.g. describe '...', openapi_spec: 'v2/swagger.json'
  config.openapi_specs = {
    'v1/swagger.yaml' => {
      openapi: '3.0.1',
      info: {
        title: 'Healthcare Messaging API V1',
        version: 'v1',
        description: 'A smart messaging system for healthcare communication between patients, doctors, and admins.',
        contact: {
          name: 'Healthcare Messaging Team',
          email: 'api@healthcaremessaging.com'
        }
      },
      paths: {},
      servers: [
        {
          url: 'http://localhost:3000',
          description: 'Development server'
        },
        {
          url: 'https://staging-api.healthcaremessaging.com',
          description: 'Staging server'
        }
      ],
      components: {
        schemas: {
          User: {
            type: :object,
            properties: {
              id: { type: :string, format: :uuid, example: '123e4567-e89b-12d3-a456-426614174000' },
              first_name: { type: :string, example: 'John' },
              last_name: { type: :string, example: 'Doe' },
              role: { type: :string, enum: %w[patient doctor admin], example: 'patient' },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: %w[id first_name last_name role]
          },
          Message: {
            type: :object,
            properties: {
              id: { type: :string, format: :uuid, example: '123e4567-e89b-12d3-a456-426614174000' },
              body: { type: :string, example: 'I need medical advice regarding chest pain.' },
              status: { type: :string, enum: %w[sent delivered read], example: 'sent' },
              routing_type: { type: :string, enum: %w[direct reply auto], example: 'direct' },
              parent_message_id: { type: :string, format: :uuid, nullable: true },
              sender: { '$ref' => '#/components/schemas/User' },
              recipient: { '$ref' => '#/components/schemas/User' },
              created_at: { type: :string, format: 'date-time' },
              updated_at: { type: :string, format: 'date-time' }
            },
            required: %w[id body status routing_type sender recipient]
          },
          Conversation: {
            type: :object,
            properties: {
              id: { type: :string, format: :uuid, example: 'abc123-def456-ghi789' },
              subject: { type: :string, example: 'Thank you for reaching out. I can help you with...' },
              participants: {
                type: :array,
                items: { '$ref' => '#/components/schemas/User' }
              },
              last_message: { '$ref' => '#/components/schemas/Message' },
              message_count: { type: :integer, example: 3 },
              created_at: { type: :string, format: 'date-time', example: '2023-01-01T10:00:00Z' }
            },
            required: %w[id subject participants last_message message_count created_at]
          },
          MessageInput: {
            type: :object,
            properties: {
              body: { type: :string, example: 'I need medical advice regarding chest pain.' },
              parent_message_id: { type: :string, format: :uuid, nullable: true }
            },
            required: ['body']
          },
          Error: {
            type: :object,
            properties: {
              error: { type: :string, example: 'Validation failed' },
              details: {
                type: :array,
                items: { type: :string },
                example: ['Body cannot be blank', 'Body is too long (maximum is 500 characters)']
              }
            },
            required: ['error']
          }
        },
        securitySchemes: {
          Bearer: {
            type: :http,
            scheme: :bearer,
            bearerFormat: 'JWT'
          }
        }
      }
    }
  }

  # Specify the format of the output Swagger file when running 'rswag:specs:swaggerize'.
  # The openapi_specs configuration option has the filename, format and
  # the output folder defined, where the file will be written to.
  config.openapi_format = :yaml
end
