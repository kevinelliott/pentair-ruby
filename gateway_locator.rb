require 'ostruct'
require 'socket'

require './messages/gateway_id_message'
require './models/gateway'

class GatewayLocator
  attr :broadcast_address, :gateway_port, :bind_ip_address, :debug

  def initialize(options = {})
    @broadcast_address  = options[:broadcast_address] || "255.255.255.255"
    @gateway_port       = options[:broadcast_port]    || 1444
    @bind_ip_address    = options[:bind_ip_address]   || '0.0.0.0'
    @debug              = false
  end

  def broadcast
    socket = UDPSocket.open
    socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
    data = [1, 0, 0, 0, 0, 0, 0, 0].pack('C*')
    socket.send(data, 0, broadcast_address, gateway_port)
    addr = socket.addr(false)
    from = OpenStruct.new(ip_address: addr[2], port: addr[1])
    socket.close
    debug_output "Sent broadcast from #{from.ip_address}:#{from.port} to #{broadcast_address}:#{gateway_port}"
    OpenStruct.new(from: from)
  end

  def listen_for_gateways
    status = broadcast
    debug_output "Listening for broadcast on #{bind_ip_address}:#{status.from.port}..."
    socket = UDPSocket.open
    socket.bind(bind_ip_address, status.from.port)
    gateway = extract_gateway(socket.recvfrom(40))
    [gateway]
  end

  def discover
    debug_output "Discovering Pentair Protocol Adapters:"
    gateways = listen_for_gateways
    gateways.each do |gateway|
      debug_output "  #{gateway.ip_address}:#{gateway.port} - Type: #{gateway.type}, Subtype: #{gateway.subtype}, Name: #{gateway.name}"
    end
    puts

    gateways
  end

  private

  def debug_output(value)
    puts "LOCATOR DEBUG: #{value}" if debug
  end

  def extract_gateway(socket_data)
    data = socket_data[0]
    message = GatewayIdMessage.read(data)

    Gateway.new(
      ip_address: [message.ip1, message.ip2, message.ip3, message.ip4].join('.'),
      port: message.gateway_port.to_i,
      type: message.gateway_type,
      subtype: message.gateway_subtype,
      name: message.gateway_name
    )
  end
end
