require 'statsample'

module BrighterPlanet
  class Billing
    # flight_sample = BrighterPlanet::Billing.emission_estimate_service.queries.sample :emitter => 'Flight'
    # assert(flight_sample.average(:emission) > 0)
    # assert(flight_sample.average(:emission) < 801)
    class Sample
      def billables
        @billables ||= []
      end
      
      def vector(k)
        billables.map { |billable| billable.send(k) }.to_scale
      end
      
      def mean(k)
        vector(k).mean
      end
    end
  end
end
