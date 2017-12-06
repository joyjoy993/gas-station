class Location
  include Mongoid::Document
  field :gps, type: Array
  field :address, type: Hash
  field :nearest_gas_station, type: Hash
  field :query_time, type: DateTime, default: DateTime.now

  validates :gps, :query_time, :address, :nearest_gas_station, presence: true
  validate :gps_valid?

  # index gps and query_time with 'unique' option
  # pros:
  # 1. can ensure cached query is uniqueness
  # 2. can log query(won't delete stale query)
  index({gps: '2d', query_time: 1}, {min: -180, max: 180, unique: true})

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
