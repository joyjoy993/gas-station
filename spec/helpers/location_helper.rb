module LocationHelper
  
  def fake_a_location_document
    fake_response = fake_a_response
    fake_gps = fake_response[:fake_gps]
    {
      address: fake_response[:address][:parsed_address],
      nearest_gas_station: fake_response[:nearest_gas_station][:parsed_address],
      gps: [fake_gps[:lng], fake_gps[:lat]]
    }
  end

end