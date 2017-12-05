class Location
  include Mongoid::Document
  field :gps, type: Array
  field :address, type: Hash
  field :nearest_gas_station, type: Hash
  field :query_time, type: DateTime, default: DateTime.now

  validates :gps, :query_time, :address, :nearest_gas_station, presence: true
  validate :gps_valid?

  index({gps: '2d'}, {min: -180, max: 180, unique: true})

  private

  def gps_valid?
    lat = gps[1]
    lng = gps[0]
    location = NearestGasValidators::GpsValidator.new(lat, lng)
    unless location.valid?
      errors.add(:gps, 'Invalid gps pair')
    end
  end

end
