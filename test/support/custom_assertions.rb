module CustomAssertions
  def assert_invalid(errors, options = {})
    loop do
      attribute, message = options.shift
      assert_includes errors[attribute], message
      errors.delete(attribute)
      break if options.empty? || errors.empty?
    end
    assert_empty options
    assert_empty errors.messages
  end

  def assert_not(object, message = nil)
    message ||= "Expected #{mu_pp(object)} to be nil or false"
    assert !object, message
  end
end