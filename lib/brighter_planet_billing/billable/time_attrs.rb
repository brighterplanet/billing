module BrighterPlanet
  class Billing
    class Billable
      module TimeAttrs
        def time_step
          if @time_step.present?
            @time_step
          elsif @minutes.present?
            1.minute
          elsif @hours.present?
            1.hour
          else
            1.day
          end
        end
    
        def start_at
          if (exact = @start_at || @first_day).present?
            exact.to_time
          elsif @minutes.present?
            now - @minutes.to_i.minutes
          elsif @hours.present?
            now - @hours.to_i.hours
          elsif @days.present?
            now - @days.to_i.days
          else
            now - (4*time_step) # 4 days ago, 4 minutes ago, etc.
          end
        end
    
        def end_at
          if (exact = @end_at || @last_day).present?
            exact.to_time
          else
            now - time_step
          end
        end
        
        def each_moment
          moment = start_at
          while moment < end_at
            yield moment.dup, { '$gte' => moment.dup, '$lt' => (moment + time_step) }
            moment += time_step
          end
        end
                
        def now
          @now || ::Time.now
        end
      end
    end
  end
end
