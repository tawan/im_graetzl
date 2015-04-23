require 'faker'

FactoryGirl.define do
  factory :address do |a|
    a.street_name { Faker::Address.street_name }
    a.street_number { Faker::Address.secondary_address }
    a.zip { Faker::Address.zip }
    a.city { Faker::Address.city }
    a.coordinates { "POINT(#{Faker::Address.longitude} #{Faker::Address.latitude})" }
    #a.description { Faker::Lorem.paragraph }

    factory :esterhazygasse do |a|
      a.street_name 'Esterházygasse'
      a.street_number '5'
      a.zip '1060'
      a.city 'Wien'
      a.coordinates 'POINT (16.353172456228375 48.194235057984216)'
    end

    factory :seestadt do |a|
      a.street_name 'Seestadtstraße'
      a.city 'Wien'
      a.coordinates 'POINT (16.508413324531308 48.219917789263086)'
    end

  end
end