module FirebaseAuthCheck
  extend ActiveSupport::Concern
  include FirebaseAuth
  include ActionController::HttpAuthentication::Token::ControllerMethods

  def authenticate_firebase_id_token
    authenticate_with_http_token do |token, _|
      return { data: get_verified_data(token) }
    rescue StandardError => e
      return { error: e.message }
    end

    return { error: "Invalid Token" }
  end
end
