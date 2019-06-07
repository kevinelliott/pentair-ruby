class LoginQueryMessage < BinData::Record
  uint16le :code1, value: Codes::MSG_CODE_1
  uint16le :code2, value: Codes::LOCALLOGIN_QUERY
  uint32le :login_size, value: lambda { login.num_bytes }
  struct :login do
    uint32le :schema, value: 348
    uint32le :connection_type, initial_value: 0
    uint32le :version_len, value: lambda { version.length }
    string :version, read_length: lambda { version_len }, initial_value: 'Local Config'
    uint32le :password_len, value: lambda { password.length }
    string :password, read_length: lambda { password_len }, initial_value: ''
    uint32le :proc_id, byte_align: 4, initial_value: 2
  end
end
