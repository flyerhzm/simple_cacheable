class Descendant < User

  belongs_to :location

  model_cache do
    with_attribute :email
    with_method :name
    with_association :location
    with_class_method :default_name
  end

  def name
    "ScotterC"
  end

  def self.default_name
    "ScotterC"
  end

end