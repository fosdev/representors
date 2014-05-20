require 'singleton'

module Representors
  module Serialization

    TOP_LEVEL_MEDIA = %w(application text)

    def known_serializers
      @known_serializers ||= begin
        serializers = Serialization.constants.select {|c| Serialization.const_get(c).is_a? Class}
        serializer_registry = []
        serializers.map do |serializer|
          klass = Serialization.const_get('%s' % serializer)
          formats = klass.formats
          media_types = klass.media_types
          serializer_registry += construed_media_types(formats, media_types).flatten.map { |mime| { mime => klass } }
        end
        serializer_registry.reduce({}, :merge)
      end
    end

    def to_media_type(media_type, options={})
      build(media_type).to_media_type(options)
    end

    def build(media_type)
      known_serializers[media_type].new(self, media_type)
    end

    def construed_media_types(formats, media_types)
      TOP_LEVEL_MEDIA.map do |top_level|
        media_types.map do |media_type|
          formats.map { |format| "#{top_level}/#{media_type}+#{format}" }
        end
      end
    end

  end
end
