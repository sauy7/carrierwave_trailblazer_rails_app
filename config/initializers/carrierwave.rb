CarrierWave.configure do |config|
  config.root = Rails.root.join('public')
  config.cache_dir = 'carrierwave'

  if Rails.env.test?
    config.enable_processing = false
  else
    config.enable_processing = true
  end
end