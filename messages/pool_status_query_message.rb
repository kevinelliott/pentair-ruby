class PoolStatusQueryMessage < BinData::Record
  uint16le :code1, value: Codes::MSG_CODE_1
  uint16le :code2, value: Codes::POOLSTATUS_QUERY
  uint32le :query_size, value: lambda { query.num_bytes }
  struct :query do
    uint32le :one, value: 0
  end
end
