ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'
require 'database_cleaner'
require 'support/custom_assertions'
require 'support/file_uploads'

DatabaseCleaner.strategy = :transaction

class ActiveSupport::TestCase
end

class MiniTest::Test
  include CustomAssertions
  include FileUploads
end

MiniTest::Spec.class_eval do
  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
    FileUtils.rm_r(Dir.glob(Rails.root.join('public/uploads/test/**')))
    FileUtils.rm_r(Dir.glob(Rails.root.join('public/carrierwave/**')))
  end
end