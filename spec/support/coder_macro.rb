module CoderMacro

  # Helper to give correct equivalent of what's in cache
  def coder(object)
    if object.is_a?(Array)
      object.map {|obj| Cacheable.send(:coder_from_record, obj) }
    else
      Cacheable.send(:coder_from_record, object)
    end
  end

end