class ProfilesController < ApplicationController
  def index
    collection Profile::Index
  end

  def new
    form Profile::Create
  end

  def create
    run Profile::Create do |op|
      return redirect_to profile_path(op.model), notice: "Profile added"
    end
    render :new
  end

  def edit
    form Profile::Update
  end

  def update
    run Profile::Update do |op|
      return redirect_to profile_path(op.model), notice: "Profile updated"
    end
    render :edit
  end

  def show
    present Profile::Update
  end

  def destroy
    run Profile::Delete do |op|
      return redirect_to profiles_path, notice: "Profile removed"
    end
    redirect_to profiles_path, alert: "Failed to remove profile"
  end
end
