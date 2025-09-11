# frozen_string_literal: true

# Base serializer for all API responses
class ApplicationSerializer
  attr_reader :object

  def initialize(object)
    @object = object
  end

  def attributes
    raise NotImplementedError, 'Subclasses must implement #attributes'
  end

  def to_h
    attributes
  end
end
