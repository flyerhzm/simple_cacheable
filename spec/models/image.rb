class Image < ActiveRecord::Base

  belongs_to :viewable, :polymorphic => true

  after_commit :do_something

  def do_something
    puts "hi"
  end
end
