require './models/circuit'
require './models/status'

class Client
  attr :debug, :status_frequency, :status, :version

  def initialize(options = {})
    if options[:hostname].nil?
      puts "client requires param :hostname"
      exit 1
    end

    @debug            = options[:debug]
    @server_hostname  = options[:hostname]
    @server_port      = options[:port] || 80
    @status_frequency = options[:status_frequency] || 5

    @connected = false
    @logged_in = false
    @version   = nil
  end

  def connected?
    @connected == true
  end

  def connect
    debug_output "Connecting to ScreenLogic 2 at #{@server_hostname}:#{@server_port}..."
    @socket = open_socket
    debug_output "Connected."
    @connected = true
  end

  def login
    send(LoginMessage.new)
    send(Message.new(code2: Codes::CHALLENGE_QUERY))
    message = decode_message(read)
    if message.code2 == Codes::CHALLENGE_ANSWER
      debug_output "We received the challenge answer."
    else
      debug_output 'No way jose, did not get expected response to challenge.'
      @logged_in = false
    end

    send(LoginQueryMessage.new(login: { password: 'beatty' }))
    message = decode_message(read)
    if message.code2 == Codes::LOCALLOGIN_ANSWER
      debug_output "Logged in."
      @logged_in = true
    else
      debug_output 'No way jose, you failed to login.'
      @logged_in = false
    end
  end

  def logged_in?
    @logged_in == true
  end

  def get_version
    send(Message.new(code2: Codes::VERSION_QUERY))
    message = decode_message(read(480))
    if message.code2 == Codes::VERSION_ANSWER
      if message.len - 4 > 0
        pool_message = PoolMessage.read(message.data)
        @version = pool_message.data
        debug_output "System version is - #{pool_message.data}"
      end
    else
      debug_output 'Something went wrong, could not get the version.'
    end
    @version
  end

  def get_status
    send(PoolStatusQueryMessage.new)
    message = decode_message(read(480))
    if message.code2 == Codes::POOLSTATUS_ANSWER
      pool_message = PoolStatusPoolMessage.read(message.data)
      debug_output "Status: #{pool_message.inspect}"
      pool_body = pool_message.bodies.select { |b| b.body_type == 0 }.first
      spa_body  = pool_message.bodies.select { |b| b.body_type == 1 }.first
      circuits  = pool_message.circuit.map do |c|
        Circuit.new(
          id: c.id,
          state: c.state,
          color: OpenStruct.new(
            set: c.color_set,
            position: c.color_position,
            stagger: c.color_stagger
          ),
          delay: c.delay
        )
      end
      @status = Status.new(
        ok: pool_message.ok,
        freeze_mode: pool_message.freeze_mode,
        remotes: pool_message.remotes,
        delays: OpenStruct.new(
          pool: pool_message.pool_delay,
          spa: pool_message.spa_delay,
          cleaner: pool_message.cleaner_delay
        ),
        air: OpenStruct.new(
          current_temp: pool_message.air_temp
        ),
        pool: OpenStruct.new(
          current_temp: pool_body.current_temp,
          heat_status: pool_body.heat_status,
          heat_set_point: pool_body.set_point,
          heat_mode: pool_body.heat_mode,
          cool_set_point: pool_body.cool_set_point
        ),
        spa: OpenStruct.new(
          current_temp: spa_body.current_temp,
          heat_status: spa_body.heat_status,
          heat_set_point: spa_body.set_point,
          heat_mode: spa_body.heat_mode,
          cool_set_point: spa_body.cool_set_point
        ),
        circuits: circuits,
        levels: OpenStruct.new(
          ph: pool_message.ph,
          ph_tank: pool_message.ph_tank,
          orp: pool_message.orp,
          orp_tank: pool_message.orp_tank,
          saturation: pool_message.saturation,
          salt_ppm: pool_message.salt_ppm
        ),
        alarms: pool_message.alarms
      )
    else
      debug_output 'Something went wrong, could not get the pool status.'
    end

    @status
  end

  def run(&block)
    loop do
      get_status
      yield(self) if block
      sleep status_frequency
    end
  end

  private

  def debug_output(value)
    puts "CLIENT DEBUG: #{value}" if debug
  end

  def decode_message(raw_message, options = {})
    klass = options[:class] || Message
    message = klass.read(raw_message)
    debug_output "Received: #{message.to_hex} => #{message.snapshot}"
    message
  end

  def open_socket
    TCPSocket.open(@server_hostname, @server_port)
  end

  def read(size = 48)
    begin
      raw_message = @socket.recv(size)
    rescue IO::WaitReadable
      IO.select([@socket])
      retry
    end
    raw_message
  end

  def send(message)
    debug_output ">> #{message.inspect} => #{message.to_hex}"
    message.write(@socket)
    # @socket.write(message.to_binary_s)
  end

  def send_string(text)
    @socket.send(text, 0)
    debug_output "Sent: #{text}" if debug
  end

end
