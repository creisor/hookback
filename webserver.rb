#!/usr/bin/env ruby

require 'socket'
require 'logger'
require 'json'
require 'uri'

HOST = '0.0.0.0'
PORT = 8081

def serve(keepalive=0, timeout=1)
  logger = Logger.new(STDERR)
  begin
    logger.info("Starting server")

    socket = Socket.new(:INET, :STREAM)
    keepalive_opt = Socket::Option.int(:INET, :SOCKET, :KEEPALIVE, keepalive)
    socket.setsockopt(keepalive_opt)
    sock_addr = Socket.sockaddr_in(PORT, HOST)
    socket.bind(sock_addr)
    socket.listen(1)

    begin
      loop do
        server, client_addrinfo = socket.accept
        client_info = "client [#{client_addrinfo.ip_address} on port #{client_addrinfo.ip_port}]"

        ready = IO.select([server], nil, nil, timeout)

        if ready
          request_line = server.gets
          logger.info("Request from #{client_info}: #{request_line.chomp}")

          headers = {}
          while line = server.gets.split(' ', 2)
            break if line[0] == ""
            headers[line[0].chop] = line[1].strip
          end
          logger.info("Headers: #{headers.inspect}")

          data = server.read(headers["Content-Length"].to_i)

          if data.empty?
            resp = build_response("Hello World!")
          else
            payload = JSON.parse(Hash[*URI.decode_www_form(data)[0]]["payload"])
            resp = build_response(JSON.pretty_generate(payload))
          end

          logger.info("Sending response to #{client_info}")
          server.print resp
        else
          logger.info("Timeout reached")
        end
      end
    ensure
      logger.info("Closing socket")
      socket.close
    end
  rescue Interrupt
    logger.info("Shutting down")
  end
end

def build_response(content)
  <<EOS
HTTP/1.1 200 OK
Content-Type: text/plain
Content-Length: #{content.bytesize}
Connection: close

#{content}
EOS
end

serve(keepalive=0, timeout=0.1)
