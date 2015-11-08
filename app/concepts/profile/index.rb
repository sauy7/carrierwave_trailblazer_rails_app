class Profile::Index < Trailblazer::Operation
  include Collection

  def model!(params)
    Profile.all
  end
end