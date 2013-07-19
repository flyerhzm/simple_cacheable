class Group < ActiveRecord::Base

  has_many :accounts

  has_many :images, as: :viewable
  accepts_nested_attributes_for :images
end
