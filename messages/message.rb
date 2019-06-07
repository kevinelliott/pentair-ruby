class Message < BinData::Record
  uint16le :code1, initial_value: Codes::MSG_CODE_1
  uint16le :code2
  uint32le :len, write_value: lambda { data.length }
  string :data, read_length: lambda { len }
end
