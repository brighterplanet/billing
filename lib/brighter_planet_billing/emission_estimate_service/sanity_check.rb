require 'eat'
require 'stringio'
require 'pp'

::Eat.config.remote_timeout ||= 5

module BrighterPlanet
  class Billing
    class EmissionEstimateService
      class SanityCheck
        attr_reader :host
        attr_reader :key
        attr_reader :selector

        def initialize(host, key, selector = {})
          @host = host
          @key = key
          @selector = selector.symbolize_keys
        end
        
        def run
          Billing.instance.emission_estimate_service.queries.top_values(50, :params, selector.merge(:key => key)).each do |params|
            Billing.instance.emission_estimate_service.queries.sample(:params => params, :key => key).billables.each do |query|
              Check.new(host, HistoricalResponse.new(query)).run
            end
          end
        end
    
        class HistoricalResponse
          attr_reader :query
      
          def initialize(query)
            @query = query
          end
      
          def to_f
            ('%0.1f' % query.emission.to_f).to_f
          end
      
          def emitter
            query.emitter
          end
      
          def params
            query.params.map { |k, v| v.to_query(k) }.join('&')
          end
      
          def pretty_params
            f = ::StringIO.new
            ::PP.pp(query.params, f)
            f.rewind
            retval = f.read
            f.close
            retval
          end
                
          def days_since
            (::Time.now - query.started_at) / 86_400 if query.started_at
          end
      
          def uri
            uri = ::URI.parse(query.url)
            uri.query = params
            uri
          end
        end

        class LiveResponse
          attr_reader :host
          attr_reader :path
          attr_reader :query
      
          def initialize(host, uri)
            @host = host
            uri = ::URI.parse(uri.to_s)
            @path = uri.path
            @query = uri.query
          end
      
          def uri(format = :txt)
            uri = ::URI.parse "http://#{host}#{path}?#{query}"
            uri.path = "#{uri.path.split('.')[0]}.#{format.to_sym}"
            uri
          end
      
          def to_f
            ('%0.1f' % txt.to_f).to_f
          end
      
          def txt
            @txt ||= eat(uri(:txt))
          end
      
          def json
            @json ||= eat(uri(:json))
          end

          def html
            @html ||= eat(uri(:html))
          end

          def xml
            @xml ||= eat(uri(:xml))
          end
        end

        class Check
          attr_reader :host
          attr_reader :historical_response

          def initialize(host, historical_response)
            @host = host
            @historical_response = historical_response
          end

          def live_response
            @live_response ||= LiveResponse.new host, historical_response.uri
          end

          def difference
            (historical_response.to_f - live_response.to_f) / historical_response.to_f * 100.0
          end

          def warning?
            difference.abs > 1
          end
          
          def run
            $stderr.puts
            if warning?
              $stderr.puts 'WARNING'
            else
              $stderr.puts 'OK'
            end
            $stderr.puts historical_response.emitter
            $stderr.puts historical_response.pretty_params
            $stderr.puts "#{historical_response.days_since} days ago"
            $stderr.puts historical_response.to_f
            $stderr.puts live_response.to_f
            $stderr.puts "#{difference}%"
            $stderr.puts live_response.uri(:html).to_s
          end
        end
      end
    end
  end
end
