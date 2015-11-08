require 'carrierwave/mount'
require 'encrypted_objects'

class Profile < ActiveRecord::Base
  class Create < Trailblazer::Operation
    include EncryptedObjects
    include Model
    model Profile, :create

    contract do
      extend CarrierWave::Mount
      mount_uploader :avatar, AvatarUploader

      property :file, virtual: true
      property :file_cache, virtual: true
      property :remove_file, virtual: true
      property :display_name

      validates :display_name, presence: true
      validates :file, file_size: { less_than: 10.kilobytes },
                file_content_type: { allow: ['image/jpeg', 'image/jpg', 'image/png', 'image/gif'] }
    end

    def process(params)
      validate(params[:profile]) do |f|
        f.save
        store_file!(f)
        return
      end
      retain_file!(contract)
    end

    private

    def file_errors(contract)
      contract.errors.messages.fetch(:file){[]}
    end

    def retain_file!(contract)
      return if file_errors(contract).present?

      if contract.file.present?
        contract.avatar = contract.file
        contract.avatar.cache!
        contract.file_cache = json_b64_encode(
            { cache_name: contract.avatar.cache_name,
              original_filename: contract.file.original_filename }
        )
      end
    end

    def persist_file!(contract)
      if contract.file.present?
        contract.avatar = contract.file
      elsif contract.file_cache.present?
        contract.avatar.retrieve_from_cache!(json_b64_decode(contract.file_cache)['cache_name'])
      end
      contract.avatar.store!
      contract.model.update_attribute(:avatar, contract.avatar.filename)
    end

    def store_file!(contract)
      return unless contract.file.present? || contract.file_cache.present?
      persist_file!(contract)
    end
  end

  class Update < Create
    action :update

    def process(params)
      remove_file!(params[:profile]) # before_validation on_update
      super
    end

    private

    def remove_stored_file!(contract)
      contract.avatar.retrieve_from_store!(contract.model.avatar)
      contract.avatar.remove!
    end

    def remove_file!(profile_params)
      return unless profile_params.fetch(:remove_file){'0'} == '1'
      remove_stored_file!(contract)
      contract.model.update_attribute(:avatar, nil)
    end

    def remove_previous_file!(contract)
      return unless contract.model.avatar.present?
      remove_stored_file!(contract)
    end

    def store_file!(contract)
      return unless contract.file.present? || contract.file_cache.present?
      remove_previous_file!(contract)
      persist_file!(contract)
    end
  end

  class Delete < Update
    def process(params)
      remove_stored_file!(contract)
      model.destroy
    end
  end
end
