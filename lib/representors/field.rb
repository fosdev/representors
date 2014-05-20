require 'yaml'

module Representors
  ##
  # Manages the respresentation of hypermedia fields for different media-types.
  class Field
    SIMPLE_METHODS = %w(name value default description type data_type).map(&:to_sym)
    VALIDATORS_KEY = :validators
    OPTIONS_KEY = :options
    SCOPE_KEY = :scope
    NAME_KEY = :name
    DEFAULT_SCOPE = 'attribute'

    # @example
    #   hash =  {field_name: {field_property: property_name}}
    #   Fields.new(hash)
    # It must only have one key/vale pair where the value is a hash
    # @param [Hash] the abstract representation of a Field
    def initialize(field_hash)
      name = field_hash.keys.first
      @field_hash = field_hash[name].clone
      @field_hash[NAME_KEY] = name
    end

    SIMPLE_METHODS.each do |meth|
      define_method(meth) { @field_hash[meth] }
    end

    # @return [String] representing the sort of field
    def scope
      @scope ||= @field_hash[SCOPE_KEY] || DEFAULT_SCOPE
    end

    # @return [Hash] The hash representation of the object
    def to_hash
      @to_hash ||= { @field_hash[NAME_KEY] => @field_hash.reject {|k,v| k == NAME_KEY } }
    end

    # @return [String] the yaml representation of the object
    def to_yaml
      @to_yaml ||= YAML.dump(to_hash)
    end

    # @return [Array] who's elements are all [Hash] objects
    def validators
      @validators ||= if @field_hash.has_key?(VALIDATORS_KEY)
        @field_hash[VALIDATORS_KEY].map { |h| h.instance_of?(Symbol) ? {h => h} : h }
      else
        []
      end
    end

    # @return [Array] who's elements are all Representors::Options objects
    def options
      @options ||= Options.new(@field_hash[OPTIONS_KEY], name)
    end

    # @returns the value of the field
    def call
      value
    end
  end
end
