require 'socket'
require 'bindata'

require 'tty-box'
require 'tty-cursor'
require 'tty-screen'

require './codes'
require './gateway_locator'
require './messages/message'
require './messages/login_message'
require './messages/login_query_message'
require './messages/pool_message'
require './messages/pool_status_pool_message'
require './messages/pool_status_query_message'
require './client'

class CommandLineInterface
  attr :gateways, :selected_gateway, :client
  attr :gateways_output, :connection_output, :status_output

  def initialize
  end

  def run
    initialize_screen

    discover_gateways
    select_gateway
    calculate_output_for_gateways
    draw_gateways

    setup_client
    connect_client

    client.run do |client|
      discover_gateways
      calculate_output_for_status

      draw_gateways
      draw_connection
      draw_status
    end
  end

  def initialize_screen
    cursor = TTY::Cursor
    cursor.clear_screen
  end

  def calculate_output_for_connection
    output = []
    output << "Connecting to gateway '#{selected_gateway.name}':"
    output << "  - Connected." if client.connected?
    output << "  - Logged in." if client.logged_in?
    output << "  - Version: #{client.version}" if client.logged_in?
    @connection_output = output.dup
  end

  def calculate_output_for_gateways
    output = []
    gateways.each do |gateway|
      output << "#{gateway.ip_address} Port #{gateway.port} #{gateway.name} (Type #{gateway.type}, Subtype #{gateway.subtype})"
    end
    @gateways_output = output.dup
  end

  def calculate_output_for_status
    output = []
    output << "  Current Temps:"
    output << "    Air  - #{client.status.air.current_temp}f"
    output << "    Pool - #{client.status.pool.current_temp}f"
    output << "    Spa  - #{client.status.spa.current_temp}f"
    output << "  Pool:"
    output << "    Current Temp: #{client.status.pool.current_temp}f"
    output << "    Heat Status: #{client.status.pool.heat_status}"
    output << "    Heat Set Point: #{client.status.pool.heat_set_point}f"
    output << "    Heat Mode: #{client.status.pool.heat_mode}"
    output << "    Cool Set Point: #{client.status.pool.cool_set_point}f"
    output << "  Spa:"
    output << "    Current Temp: #{client.status.spa.current_temp}f"
    output << "    Heat Status: #{client.status.spa.heat_status}"
    output << "    Heat Set Point: #{client.status.spa.heat_set_point}f"
    output << "    Heat Mode: #{client.status.spa.heat_mode}"
    output << "    Cool Set Point: #{client.status.spa.cool_set_point}f"
    output << "  Circuits:"
    client.status.circuits.each do |circuit|
      output << "    #{circuit.id} - #{circuit.state_message}"
    end
    @status_output = output.dup
  end

  def connect_client
    client.connect
    calculate_output_for_connection
    draw_connection

    client.login
    calculate_output_for_connection
    draw_connection

    client.get_version
    calculate_output_for_connection
    draw_connection
  end

  def discover_gateways
    @gateways = GatewayLocator.new.discover
  end

  def draw_gateways
    gateways_box = TTY::Box.frame(
      width: TTY::Screen.width / 2,
      height: 10,
      top: 0,
      left: 0,
      padding: 1,
      title: { top_left: 'Pentair Gateways', bottom_right: "#{gateways.count} detected" }
    ) do
      gateways_output.join("\n")
    end
    puts gateways_box
  end

  def draw_connection
    connect_box = TTY::Box.frame(
      width: TTY::Screen.width / 2,
      height: 10,
      top: 11,
      left: 0,
      padding: 1,
      title: { top_left: 'Connection', bottom_right: "Connected!" }
    ) do
      connection_output.join("\n")
    end
    puts connect_box
  end

  def draw_status
    status_box = TTY::Box.frame(
      width: TTY::Screen.width / 2,
      height: 60,
      top: 0,
      left: TTY::Screen.width / 2,
      padding: 1,
      title: { top_left: 'Status', bottom_right: "" }
    ) do
      status_output.join("\n")
    end
    puts status_box
  end

  def select_gateway
    @selected_gateway = gateways.first
  end

  def setup_client
    @client = Client.new(
      hostname: selected_gateway.ip_address,
      port: selected_gateway.port,
      debug: false
    )
  end

end

CommandLineInterface.new.run
