class Group < ActiveRecord::Base

  has_many :accounts

  has_many :images, as: :viewable
end
