require 'test_helper'

class ProfileIndexTest < MiniTest::Spec
  describe "Index" do
    it "present returns a collection of profiles" do
      res, op = Profile::Create.run(profile: { display_name: 'Bluebell', file: avatar_file })
      profile = op.model
      res = Profile::Index.present({})
      assert_equal profile, res.model.first
    end
  end
end
