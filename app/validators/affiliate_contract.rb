class AffiliateContract < Dry::Validation::Contract
  params do
    required(:email).value(Types::SquisedString)
    required(:first_name).value(Types::SquisedString)
    required(:last_name).value(Types::SquisedString)
    optional(:commissions_total).value(Types::ConvertedFloats)
    optional(:website_url).maybe(:string)
  end

  rule(:email) do
    unless EmailValidator.valid?(value, mode: :strict, require_fqdn: true)
      key.failure("Email should have valid format")
    end
  end

  rule(:first_name) do
    unless value.present?
      key.failure("First name is required")
    end
  end

  rule(:last_name) do
    unless value.present?
      key.failure("Last name is required")
    end
  end

  rule(:commissions_total) do
    unless value >= 0
      key.failure("Commission total should be a numeric and greater than or equal to zero")
    end
  end
end
