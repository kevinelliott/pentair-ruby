class LoginMessage < BinData::Record
  string :connect, value: "CONNECTSERVERHOST\r\n\r\n"
end
