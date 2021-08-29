module SimplePlot
    class DerivedFunctionCalculator 
        attr_accessor :derived_data_set

        def initialize(derived_data_set)
            @derived_data_set = derived_data_set
        end 

        def derive_values(data_set_name, referenced_data_sets, visible_range, hh)
            # TODO Should we derive all values, or just the new one?
            # There are two cases
            #   1. the visible range changes, so we need to do everything
            #   2. we added a new data set, so just that one needs to be added

            data_points = []
            metrics = Stats.new(data_set_name)

            # x is implied, so for our purposes here, exclude it from the set
            # of reference data sets
            referenced_data_sets.delete("x")
            #puts "derive value for #{data_set_name}: ref_data_sets:  #{referenced_data_sets}"

            x_axis_values_to_calculate = visible_range.calc_x_values
            referenced_data_sets.each do |dsn| 
                #puts "The x values for #{dsn} are #{hh.keys(dsn)}"
                x_axis_values_to_calculate.push(*hh.keys(dsn))
            end

            x_axis_values_to_calculate.each do |x| 
                metrics.increment("total_x_points")
                code = ""
                missing_a_referenced_value = false
                referenced_data_sets.each do |dsn| 
                    other_derived_value = hh.get(dsn, x)
                    if other_derived_value.nil?
                        #puts "INFO: No derived value for #{dsn} where x=#{x}"
                        missing_a_referenced_value = true
                        metrics.increment(dsn)
                    end
                    code = "#{code}\n#{dsn} = #{other_derived_value}"
                end
                code = "#{code}\n#{@derived_data_set.function_str}"

                if missing_a_referenced_value
                    #puts "INFO: Cannot calculate point for #{data_set_name} at x=#{x}"
                else
                    y = eval(code)
                    #puts "#{y} = [#{x}] #{@derived_data_set.function_str}"
                    data_points << DataPoint.new(x, y)
                    hh.set(data_set_name, x, y) 
                end
            end

            #metrics.display_counts 
            data_points
        end 
    end
end
