class Account < ActiveRecord::Base
  belongs_to :user

  belongs_to :group

  belongs_to :account_location, class_name: Location,
                                foreign_key: :account_location_id

  model_cache do
    with_association :user, :account_location
  end
end
