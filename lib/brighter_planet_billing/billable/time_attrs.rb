module BrighterPlanet
  class Billing
    class Billable
      module ::TimeAttrs
        def precision
          if @hours.present?
            1.hour
          else
            1.day
          end
        end
    
        def start_at
          if (exact = @start_at || @first_day).present?
            exact.to_time
          elsif @hours.present?
            now - @hours.to_i.hours
          elsif @days.present?
            now - @days.to_i.days
          else
            now - 3.days
          end
        end
    
        def end_at
          if (exact = @end_at || @last_day).present?
            exact.to_time
          elsif @hours.present?
            now
          else
            now - 1.days
          end
        end
                
        def now
          @now || ::Time.now
        end
      end
    end
  end
end
