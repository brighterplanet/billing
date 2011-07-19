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
            when 1.week
              :week
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
          elsif @weeks.present?
            @chosen_period = :week
            1.week
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
            now - @minutes.to_f.minute
          when :hour
            now - @hours.to_f.hour
          when :day
            now - @days.to_f.day
          when :week
            now - @weeks.to_f.week
          when :month
            (now - @months.to_f.month).at_beginning_of_month
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
            yield moment.dup, { '$gte' => moment.dup.utc, '$lt' => (moment + period).utc }
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
          @now || ::Time.now.utc
        end
        
        def selector_with_time_attrs
          if (@start_at or @end_at or @minutes or @hours or @days or @weeks or @months) and selector_without_time_attrs[:started_at].nil?
            selector_without_time_attrs.merge :started_at => { '$gte' => start_at.utc, '$lt' => end_at.utc }
          else
            selector_without_time_attrs
          end
        end
      end
    end
  end
end
