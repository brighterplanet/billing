module BrighterPlanet
  class Billing
    class Billable
      module EachHash
        def each_hash
          reference = columns
          each do |row|
            row_as_hash = columns.inject({}) do |memo, k|
              memo[k] = row[reference.index(k)]
              memo
            end
            yield row_as_hash
          end
        end
      end
    end
  end
end
