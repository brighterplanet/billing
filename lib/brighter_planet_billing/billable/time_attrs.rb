module BrighterPlanet
  class Billing
    class Billable
      module TimeAttrs
        def period
          @_period ||= if @period.present?
            @chosen_period = case @period
            when 1.minute
              :minute
            when 1.hour
              :hour
            when 1.day
              :day
            when 1.month
              :month
            else
              :custom
            end
            @period
          elsif @minutes.present?
            @chosen_period = :minute
            1.minute
          elsif @hours.present?
            @chosen_period = :hour
            1.hour
          elsif @days.present?
            @chosen_period = :day
            1.day
          else
            @chosen_period = :month
            1.month
          end
        end
        
        def chosen_period
          period # force calc
          @chosen_period
        end

        def start_at
          return @start_at.to_time if @start_at.present?
          case chosen_period
          when :minute
            now - @minutes.to_i.minute
          when :hour
            now - @hours.to_i.hour
          when :day
            now - @days.to_i.day
          when :month
            (now - @months.to_i.month).at_beginning_of_month
          else
            now - (4*period) # 4 day ago, 4 minute ago, etc.
          end
        end

        def end_at
          return @end_at.to_time if @end_at.present?
          case chosen_period
          when :month
            now.at_beginning_of_month
          else
            now - period
          end
        end

        def each_moment
          $stderr.puts "[brighter_planet_billing period] starting at #{start_at} with period #{period}" if ::ENV['BRIGHTER_PLANET_BILLING_DEBUG'] and ::ENV['BRIGHTER_PLANET_BILLING_DEBUG'].include?('period')
          moment = start_at
          while moment < end_at
            $stderr.puts "[brighter_planet_billing period] * from #{moment} to #{moment + period}}" if ::ENV['BRIGHTER_PLANET_BILLING_DEBUG'] and ::ENV['BRIGHTER_PLANET_BILLING_DEBUG'].include?('period')
            yield moment.dup, { '$gte' => moment.dup, '$lt' => (moment + period) }
            moment += period
          end
        end

        def period_starting(time)
          if period < 1.day
            time.to_s :db
          else
            time.to_date.to_s
          end
        end

        def now
          @now || ::Time.now
        end
      end
    end
  end
end
