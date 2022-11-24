class ApplicationController < ActionController::API
  include FirebaseAuth
  include Api::ExceptionHandler
  include ActionController::HttpAuthentication::Token::ControllerMethods

  private

  def authenticate
    authenticate_with_http_token do |token, _options|
      result = verify_id_token(token)

      if uid = result[:uid]
        @_current_user ||= User.find_or_create_by!(uid: uid)
      else
        render_400(nil, result[:errors])
      end
    end
  end

  def current_user
    @_current_user
  end
end
