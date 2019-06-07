class PoolMessage < BinData::Record
  uint32le :len, write_value: lambda { data.length }
  string :data, read_length: lambda { len }
end
