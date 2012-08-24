module Danthes
  # This class is an extension for the Faye::RackAdapter.
  # It is used inside of Danthes.faye_app.
  class FayeExtension
    # Callback to handle incoming Faye messages. This authenticates both
    # subscribe and publish calls.
    def incoming(message, callback)
      if message["channel"] == "/meta/subscribe"
        authenticate_subscribe(message)
      elsif message["channel"] !~ %r{^/meta/}
        authenticate_publish(message)
      end
      callback.call(message)
    end

  private

    # Ensure the subscription signature is correct and that it has not expired.
    def authenticate_subscribe(message)
      subscription = Danthes.subscription(:channel => message["subscription"], 
                                          :timestamp => message["ext"]["danthes_timestamp"])
      if message["ext"]["danthes_signature"] != subscription[:signature]
        message["error"] = "Incorrect signature."
      elsif Danthes.signature_expired? message["ext"]["danthes_timestamp"].to_i
        message["error"] = "Signature has expired."
      end
    end

    # Ensures the secret token is correct before publishing.
    def authenticate_publish(message)
      if Danthes.config[:secret_token].nil?
        raise Error, "No secret_token config set, ensure danthes.yml is loaded properly."
      elsif message["ext"]["danthes_token"] != Danthes.config[:secret_token]
        message["error"] = "Incorrect token."
      else
        message["ext"]["danthes_token"] = nil
      end
    end
  end
end
