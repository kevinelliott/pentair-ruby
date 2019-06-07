class Circuit < OpenStruct
  def state_message
    case state
    when 0 then 'Off'
    when 1 then 'On'
    end
  end
end