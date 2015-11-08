require 'test_helper'
require 'encrypted_objects'

class ProfileCrudTest < MiniTest::Spec
  include EncryptedObjects

  describe "Create" do
    it "is valid without an avatar file" do
      res, op = Profile::Create.run(profile: { display_name: 'Bluebell', file: '' })
      profile = op.model

      assert res
      assert_equal 'Bluebell', profile.display_name
      assert_nil profile.avatar
    end

    it "is invalid without a display_name but retains valid file" do
      res, op = Profile::Create.run(profile: { display_name: '', file: avatar_file })
      cache = op.contract.file_cache

      assert_not res
      assert_invalid op.errors, { display_name: "can't be blank" }
      assert_match /[a-z0-9]{108}/i, cache
      assert File.exists?(Rails.root.join('public/carrierwave', json_b64_decode(cache)['cache_name']))
    end

    it "is invalid with an unsupported file format, file discarded" do
      res, op = Profile::Create.run(profile: { display_name: 'Bluebell', file: text_file })

      assert_not res
      assert_invalid op.errors, { file: "file should be one of image/jpeg, image/jpg, image/png, image/gif" }
      assert_nil op.contract.file_cache
    end

    it "is invalid with a too large avatar file, file discarded" do
      res, op = Profile::Create.run(profile: { display_name: 'Bluebell', file: invalid_avatar_file })

      assert_not res
      assert_invalid op.errors, { file: "file size must be less than 10 KB" }
      assert_nil op.contract.file_cache
    end

    # NOTE: We're not testing the AvatarUploader in isolation as we are triggering caching and storing manually from
    # within the operation
    describe "file uploads" do
      before do
        AvatarUploader.enable_processing = true
      end

      after do
        AvatarUploader.enable_processing = false
      end

      it "creates a valid profile and persists file" do
        res, op = Profile::Create.run(profile: { display_name: 'Bluebell', file: avatar_file })
        profile = op.model

        assert res
        assert_equal 'Bluebell', profile.display_name
        assert_equal 'avatar.jpg', profile.avatar
        assert File.exists?(Rails.root.join("public/uploads/test/profile/avatar/#{profile.id}/avatar.jpg"))
      end

      it "persists previously retained file" do
        res, op = Profile::Create.run(profile: { display_name: 'Bluebell', file_cache: retained_file })
        profile = op.model

        assert res
        assert_equal 'avatar.jpg', profile.avatar
        assert File.exists?(Rails.root.join("public/uploads/test/profile/avatar/#{profile.id}/avatar.jpg"))
      end
    end
  end

  describe "Update" do
    before do
      AvatarUploader.enable_processing = true
      res, @op = Profile::Create.run(profile: { display_name: 'Bluebell', file: avatar_file })
    end

    after do
      AvatarUploader.enable_processing = false
    end

    describe "updates to avatar file" do
      it "allows removal of avatar file" do
        res, op = Profile::Update.run(id: @op.model.id, profile: { remove_file: '1' })
        profile = op.model

        assert res
        assert_nil profile.avatar
        assert_not File.exists?(Rails.root.join("public/uploads/test/profile/avatar/#{profile.id}/avatar.jpg"))
      end

      it "allows replacement of avatar file" do
        res, op = Profile::Update.run(id: @op.model.id, profile: { file: new_file })
        profile = op.model

        assert res
        assert_equal 'new.png', profile.avatar
        assert_not File.exists?(Rails.root.join("public/uploads/test/profile/avatar/#{profile.id}/avatar.jpg"))
        assert File.exists?(Rails.root.join("public/uploads/test/profile/avatar/#{profile.id}/new.png"))
      end
    end
  end

  describe "Delete" do
    before do
      AvatarUploader.enable_processing = true
      res, @op = Profile::Create.run(profile: { display_name: 'Bluebell', file: avatar_file })
    end

    after do
      AvatarUploader.enable_processing = false
    end

    it "deletes the profile and removes the avatar file" do
      profile = @op.model

      res, op = Profile::Delete.run(id: profile.id)

      assert res
      assert_not op.model.persisted?
      assert_not File.exists?(Rails.root.join("public/uploads/test/profile/avatar/#{profile.id}/avatar.jpg"))
    end
  end
end
