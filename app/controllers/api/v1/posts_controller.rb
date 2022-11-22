class Api::V1::PostsController < ActionController::API
  include FirebaseAuthCheck

  before_action :set_auth, only: %i[create update delete]

  def index
    posts = Post.all
    render json: { data: posts }
  end

  def create
    if @auth[:error]
      render json: @auth, status: :unauthorized
      return
    end

    uid = @auth[:data]["user_id"]
    user = User.find_by(uid: uid)
    unless user
      render json: { message: "User does not exit! " }, status: :bad_request
      return
    end

    post_params[:user] = user
    post = user.posts.new(post_params)
    if post.save
      render json: { data: { post: post, uid: user.uid } }
    else
      render json: post.errors.messages, status: :unprocessable_entity
    end
  end

  def update
  end

  def delete
  end

  private

  def set_auth
    @auth = authenticate_firebase_id_token
  end

  def post_params
    params.fetch(:post, {}).permit(:title, :body)
  end
end
