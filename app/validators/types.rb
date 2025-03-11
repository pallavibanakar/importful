module Types
  include Dry::Types()

  SquisedString = Types::String.constructor(&:squish)
  ConvertedFloats = Types::Float.constructor(&:to_f)
end
