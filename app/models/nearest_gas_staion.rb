class NearestGasStaion
  include Mongoid::Document
  field :gps, type: Array
  field :address, type: String
  field :nearest_gas_station, type: Hash
  field :query_time, type: Time, default: Time.now
end
