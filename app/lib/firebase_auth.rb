# This module helps to verify a Firebase JWT ID token according to rules:
# https://firebase.google.com/docs/auth/admin/verify-id-tokens#verify_id_tokens_using_a_third-party_jwt_library
#
# Note: you need to decode the token twice.
#   1. Decode without verification. To grab the key id from the header,
#     in order to grab the certificate where the key is the key id.
#   2. Then decode for verification.

require "jwt"
require "net/http"

module FirebaseAuth
  ISSUER_PREFIX = "https://securetoken.google.com/".freeze
  ALGORITHM = "RS256".freeze

  # The firebase project id will be used as the [aud] - Audience,
  # and in the issuer url as "https://securetoken.google.com/<FIREBASE_PROJECT_ID>"
  FIREBASE_PROJECT_ID = ENV["FIREBASE_PROJECT_ID"]

  # The url to load public key certificates.
  # The key of the certificates is the key id from the token header.
  CERT_URI =
    "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com".freeze

  # The wrapper of verification:
  #   1. Decode the token without verification in order to grab the header;
  #   2. Get the public key using the key ID from the header;
  #   3. Verify the token with the public key;
  #   4. Raise error if there is any;
  #   5. When all verifications are successful, return the paylaod(user data);
  #
  # Payload returned:
  # {
  #   "name": "<username>",
  #   "picture": "<user_profile_picture>",
  #   "iss": "https://securetoken.google.com/<FIREBASE_PROJECT_ID>",
  #   "aud": "<firebase_project_id>",
  #   "auth_time": 1668430866,
  #   "user_id": "<user_id>(same as sub)",
  #   "sub": "<subject>",
  #   "iat": 1668488296,
  #   "exp": 1668491896,
  #   "email": "<user email>",
  #   "email_verified": true,
  #   "firebase": {
  #     "identities": {
  #       "google.com": [
  #         "<google_user_id>"
  #       ],
  #       "email": [
  #         "<user_gmail>"
  #       ]
  #     },
  #     "sign_in_provider": "google.com"
  #   }
  # }
  def get_verified_data(id_token)
    payload, header = decode_unverified(id_token)
    public_key = get_public_key(header)

    error = verify_token(id_token, public_key)
    raise error unless error.nil?

    return payload
  end

  private

  # Returns:
  #   decoded data of ID token, as [{payload hash},{headers hash}]
  def decode_token(token:, key:, verify:, options:)
    JWT.decode(token, key, verify, options)
  end

  # No verification is done here. The `verify`` arg is set to `false`.
  # This is to extract the key ID from the header in order to
  # acquire the appropriate certificate to verify the token.
  def decode_unverified(token)
    decode_token(
      token: token,
      key: nil,
      verify: false,
      options: {
        algorithm: ALGORITHM,
      },
    )
  end

  # Use the kid - Key ID in headers to get the corrosponding public key
  def get_public_key(header)
    certificate = find_certificate(header["kid"])
    public_key = OpenSSL::X509::Certificate.new(certificate).public_key
  rescue OpenSSL::X509::CertificateError => e
    raise "Invalid certificate. #{e.message}"

    return public_key
  end

  # Find the corresponding certificate where the key is kid
  # Certificates fetched from Goolge is like:
  # {
  #   "key_1": "CERTIFICATE_1",
  #   "key_2": "CERTIFICATE_2"
  # }
  def find_certificate(kid)
    certificates = fetch_certificates
    unless certificates.keys.include?(kid)
      raise "Invalid 'kid', do not correspond to one of valid public keys."
    end

    valid_certificate = certificates[kid]
    return valid_certificate
  end

  # Fetches valid google public key certificates from CERT_URL
  def fetch_certificates
    uri = URI.parse(CERT_URI)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true

    req = Net::HTTP::Get.new(uri.path)
    res = https.request(req)
    unless res.code == "200"
      raise "Error: can't obtain valid public key certificates from Google."
    end

    certificates = JSON.parse(res.body)
    return certificates
  end

  # Verify the signature and data for the provided JWT token.
  # Return error messages if something wrong with the token.
  def verify_token(token, key)
    # Verify the signature and data, excluding subject and algorithm
    begin
      decoded_token =
        decode_token(
          token: token,
          key: key,
          verify: true,
          options: decode_options,
        )
    rescue JWT::ExpiredSignature
      return(
        "Firebase ID token has expired. Get a fresh token from your app and try again."
      )
    rescue JWT::InvalidIatError
      return "Invalid ID token. 'Issued-at time' (iat) must be in the past."
    rescue JWT::InvalidIssuerError
      return(
        "Invalid ID token. 'Issuer' (iss) Must be 'https://securetoken.google.com/<firebase_project_id>'."
      )
    rescue JWT::InvalidAudError
      return(
        "Invalid ID token. 'Audience' (aud) must be your Firebase project ID."
      )
    rescue JWT::VerificationError => e
      return "Firebase ID token has invalid signature. #{e.message}"
    end

    # If the above verifications are successful,
    # finally, verify subject ("sub") and algorithm ("alg")
    verify_sub_and_alg(decoded_token)
  end

  def decode_options
    {
      iss: ISSUER_PREFIX + FIREBASE_PROJECT_ID,
      aud: FIREBASE_PROJECT_ID,
      algorithm: ALGORITHM,
      verify_iat: true,
      verify_iss: true,
      verify_aud: true,
    }
  end

  def verify_sub_and_alg(decoded_token)
    sub = decoded_token[0]["sub"]
    alg = decoded_token[1]["alg"]

    unless sub.is_a?(String) && !sub.empty?
      return "Invalid ID token. 'Subject' (sub) must be a non-empty string."
    end

    unless alg == ALGORITHM
      return "Invalid ID token. 'alg' must be '#{ALGORITHM}', but got #{alg}."
    end

    return nil
  end
end
