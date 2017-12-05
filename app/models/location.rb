class Location
  include Mongoid::Document
  field :gps, type: Array
  field :address, type: Hash
  field :nearest_gas_station, type: Hash
  field :query_time, type: DateTime, default: DateTime.now

  validates :gps, :query_time, :address, :nearest_gas_station, presence: true

  index({gps: '2d'}, {min: -180, max: 180, unique: true})

end
