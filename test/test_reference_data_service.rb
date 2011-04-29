require 'helper'

class TestReferenceDataService < Test::Unit::TestCase
  def test_000_bill_download
    BrighterPlanet::Billing.reference_data_service.bill do |download|
      download.remote_ip = '1.1.1.1'
      download.resource = 'Airline'
      download.format = :csv
      download.earth_version = '2acd0'
      download.content_length = 1_293
      download.source = '/tmp/data1_snapshots/foobar.csv'
      download.line_count = 400
      download.key = 'test_000_bill_download'
    end
  end
end
