class Api::V1::AuthenticationsController < ApplicationController
  before_action :authenticate

  def create
    render json: { message: "User successfully logged in!" }, status: :ok
  end
end
