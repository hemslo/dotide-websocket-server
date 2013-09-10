require 'em-websocket'
require 'em-http-request'
require 'json'

def required_attributes(params, keys)
  attrs = {}
  keys.each do |key|
    return false unless (params.has_key?(key) && !params[key].nil?)
    attrs[key] = params[key]
  end
  attrs
end

BASE_URL = 'http://127.0.0.1:9292'

EM.run {
  EM::WebSocket.run(:host => "0.0.0.0", :port => 8000) do |ws|
    ws.onopen { |handshake|
      puts "WebSocket connection open"

      # Access properties on the EM::WebSocket::Handshake object, e.g.
      # path, query_string, origin, headers

      # Publish message to the client
      ws.send "Hello Client, you connected to #{handshake.path}"
    }

    ws.onclose { puts "Connection closed" }

    ws.onmessage { |msg|
      puts "Recieved message: #{msg}"
      params = required_attributes(JSON.parse(msg), ['method', 'path','headers', 'body'])
      return unless (params && %w(get post put delete).include?(params['method']))
      p params
      method = params['method'].to_sym
      url = BASE_URL + params['path']
      req = EM::HttpRequest.new(url)
      if req.respond_to? method
        http = req.send(method, { head: params['headers'], body: params['body'] })
      end
      http.callback {
        res = {
          status: http.response_header.status,
          headers: http.response_header,
          body: http.response
        }
        p res
        ws.send "return: #{res.to_json}"
     }
      # ws.send "Pong: #{msg}"
    }
  end
}
