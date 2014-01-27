class Descendant < User

  model_cache do
    with_attribute :email
    with_method :name
    with_class_method :default_name
  end

  def name
    "ScotterC"
  end

  def self.default_name
    "ScotterC"
  end

end