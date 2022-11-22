class Api::V1::UsersController < ActionController::API
  include FirebaseAuthCheck

  before_action :set_auth, only: %i[create]

  def create
    if @auth[:error]
      render json: @auth, status: :unauthorized
      return
    end

    uid = @auth[:data]["user_id"]
    name = @auth[:data]["name"]
    if User.find_by(uid: uid)
      render json: { message: "User is logged in successfully!" } and return
    end

    user = User.new(name: name, uid: uid)
    if user.save
      render json: { message: "User is created successfully!" }
    else
      render json: user.errors.messages, status: :unprocessable_entity
    end
  end

  private

  def set_auth
    @auth = authenticate_firebase_id_token
  end
end
