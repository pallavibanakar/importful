FactoryBot.define do
  factory :notification do
    association :merchant, factory: :merchant
    errors_file { nil }
    type { 'AffiliateImport' }
    message { 'Sample message' }
    title { 'Sample title' }
    read_at { nil }
  end
end
