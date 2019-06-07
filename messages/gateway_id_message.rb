class GatewayIdMessage < BinData::Record
  uint32le :check
  uint8 :ip1
  uint8 :ip2
  uint8 :ip3
  uint8 :ip4
  uint16le :gateway_port
  uint8 :gateway_type
  uint8 :gateway_subtype
  stringz :gateway_name
end