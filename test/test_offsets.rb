class TestOffsets < Test::Unit::TestCase  
  def test_usage
    ::BrighterPlanet.billing.config.disable_caching = true
    execution_id = nil
    ::BrighterPlanet.billing.offsets.bill do |query|
      query.price = 20.82
      query.co2 = 1827.83
      query.key = 'ABC123'
      execution_id = query.execution_id
    end
    sleep 1
    stored_query = ::BrighterPlanet.billing.offsets.purchases.find_one(:execution_id => execution_id)
    assert_equal 'Offsets', stored_query.service
    assert_equal 20.82, stored_query.price
    assert_equal 1827.83, stored_query.co2
    assert_equal 'ABC123', stored_query.key
  end
end
