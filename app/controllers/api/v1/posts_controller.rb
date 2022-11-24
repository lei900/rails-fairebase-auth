class Api::V1::PostsController < ApplicationController
  skip_before_action :authenticate_token, only: %i[index show]
  before_action :set_post, only: %i[show update destroy]

  def index
    posts = Post.all
    render json: posts
  end

  def show
    render json: @post
  end

  def create
    post = current_user.posts.new(post_params)
    if post.save
      render json: post
    else
      render_400(nil, article.errors.full_messages)
    end
  end

  def update
    if @post.update(post_params)
      render json: @post
    else
      render_400(nil, @post.errors.full_messages)
    end
  end

  def destroy
    current_user.posts.find_by(params[:id]).destroy!
    render json: { message: "Post deleted successfully" }, status: :ok
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :body)
  end
end
