class PoolStatusPoolMessage < BinData::Record
  int32le :ok
  uint8 :freeze_mode
  uint8 :remotes
  uint8 :pool_delay
  uint8 :spa_delay
  uint8 :cleaner_delay
  uint8 :thing1
  uint8 :thing2
  uint8 :thing3
  int32le :air_temp
  int32le :bodies_count
  array :bodies, initial_length: :bodies_count do
    int32le :body_type
    int32le :current_temp
    int32le :heat_status
    int32le :set_point
    int32le :cool_set_point
    int32le :heat_mode
  end
  int32le :circuit_count
  array :circuit, initial_length: :circuit_count do
    int32le :id
    int32le :state
    uint8 :color_set
    uint8 :color_position
    uint8 :color_stagger
    uint8 :delay
  end
  int32le :ph
  int32le :orp
  int32le :saturation
  int32le :salt_ppm
  int32le :ph_tank
  int32le :orp_tank
  int32le :alarms
end
