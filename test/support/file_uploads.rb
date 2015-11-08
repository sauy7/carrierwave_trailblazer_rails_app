require 'encrypted_objects'

module FileUploads
  include EncryptedObjects

  def avatar_file
    uploaded_file('avatar.jpg', 'image/jpg')
  end

  def invalid_avatar_file
    uploaded_file('large.png')
  end

  def new_file
    uploaded_file('new.png')
  end

  def text_file
    uploaded_file('test.txt', 'text/plain')
  end

  def uploaded_file(filename, type = "image/png")
    file_path = Rails.root.join("test/fixtures/#{filename}")
    ActionDispatch::Http::UploadedFile.new(tempfile: File.new(file_path),
                                           filename: File.basename(file_path),
                                           type: type)
  end

  def retained_file(filename = 'avatar.jpg')
    cache_id = Time.now.utc.to_i.to_s + '-' + Process.pid.to_s + '-' + ("%04d" % rand(9999))
    FileUtils.mkdir_p(Rails.root.join('public/carrierwave', cache_id))
    FileUtils.cp(Rails.root.join('test/fixtures', filename), Rails.root.join('public/carrierwave', cache_id, filename))
    json_b64_encode({ cache_name: "#{cache_id}/#{filename}", original_filename: filename })
  end
end