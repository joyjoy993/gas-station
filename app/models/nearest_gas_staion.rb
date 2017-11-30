class NearestGasStaion
  include Mongoid::Document
  field :lat, type: String
  field :lng, type: String
  field :addresses, type: Array
  field :nearest_gas_station, type: Hash
  field :query_time, type: Time, default: Time.now
end
