########################################################################
# Logic cover classes: used for describing covers of boolean functions #
########################################################################


require "logic_tools/minimal_column_covers.rb"

module LogicTools

    ## 
    #  Represents a boolean cube.
    class Cube
        
        ## Creates a new cube from a bit string +bits+.
        def initialize(bits)
            @bits = bits.to_s
            unless @bits.match(/^[01-]*$/)
                raise "Invalid bit string for describing a cube: "+ @bits
            end
        end

        ## Gets the width (number of variables of the boolean space).
        def width
            return @bits.length
        end

        ## Evaluates the corresponding function's value for a binary +input+.
        #
        #  +input+ is assumed to be an integer.
        #  Returns the evaluation result as a boolean.
        def eval(input)
            result = true
            @bits.each_with_index do |bit,i|
                if bit == "1" then
                    result &= ((input & (2**i)) != 0)
                elsif bit == "0" then
                    result &= ((input & (2**i)) == 0)
                end
            end
            return result
        end

        ## Computes the distance with another +cube+.
        def distance(cube)
            return @bits.each_char.with_index.count do |b,i|
                b != "-" and cube[i] != "-" and b != cube[i]
            end
        end

        ## Converts to a string.
        def to_s # :nodoc:
            @bits.clone
        end

        ## Iterates over the bits of the cube.
        # 
        #  Returns an enumerator if no block given.
        def each_bit(&blk)
            # No block given? Return an enumerator.
            return to_enum(:each_bit) unless block_given?
            
            # Block given? Apply it on each bit.
            @bits.each_char(&blk)
        end
        alias each each_bit

        ## The bit string defining the cube.
        #
        #  Should not be modified directly, hence set as protected.
        attr_reader :bits
        protected :bits

        ## Compares with another +cube+.
        def ==(cube) # :nodoc:
            @bits == cube.bits
        end
        alias eql? ==
        def <=>(cube) #:nodoc:
            @bits <=> cube.bits
        end

        ## Gets the hash of a cube
        def hash
            @bits.hash
        end

        ## duplicates the cube.
        def clone # :nodoc:
            Cube.new(self)
        end
        alias dup clone

        ## Gets the value of bit +i+.
        def [](i)
            @bits[i]
        end

        ## Sets the value of bit +i+ to +b+.
        def []=(i,b)
            raise "Invalid bit value: #{b}" unless ["0","1","-"].include?(b)
            # Update the bit string
            @bits[i] = b 
        end

        ## Computes the consensus with another +cube+.
        #
        #  Returns the concensus cube if any.
        def consensus(cube)
            # Step 1: compute the distance between the cubes.
            dist = self.distance(cube)
            # Step 2: depending on the distance.
            return nil if (dist != 1) # Distance is not 1: no consensus
            # Distance is 1, the consensus is a single cube
            # built by setting to "-" the opposite variable, and
            # keeping all the other.
            cbits = "-" * cube.width
            @bits.each_char.with_index do |bit,i|
                if bit != "-" then
                    cbits[i] = bit if (cube[i] == "-" or cube[i] == bit)
                else
                    cbits[i] = cube[i]
                end
            end
            return Cube.new(cbits)
        end

        ## Computes the sharp operation with another +cube+.
        #
        #  Returns the resulting list of cubes as an array.
        #  
        #  (NOTE: not as a cover).
        def sharp(cube)
            result = []
            # There is one such cube per litteral which is in
            # self but not in cube.
            @bits.each_char.with_index do |bit,i|
                next if (cube[i] == "-" or cube[i] == bit)
                cbits = @bits.clone
                cbits[i] = (cube[i] == "0") ? "1" : "0"
                result << Cube.new(cbits)
            end
            # Remove duplicate cubes before ending.
            result.uniq!
            return result
        end

        ## Checks if +self+ can be merged with +cube+
        def can_merge?(cube)
            found = false # 0 to 1 or 1 to 0 pattern found
            @bits.each_char.with_index do |bit,i|
                if (bit != cube[i]) then
                    # Found one different bit
                    return false if found # But there were already one
                    found = true
                end
            end
            # Can be merged
            return true
        end

        ## Merges +self+ with +cube+ if possible.
        #
        #  Returns the merge result as a new cube, or nil in case of failure.
        def merge(cube)
            # Create the bit string of the result.
            cbits = "-" * self.width
            found = false # 0 to 1 or 1 to 0 pattern found
            @bits.each_char.with_index do |bit,i|
                if (bit != cube[i]) then
                    # Found one different bit
                    return nil if found # But there were already one
                    found = true
                else
                    cbits[i] = bit
                end
            end
            # Can be merged
            return Cube.new(cbits)
        end

        ## Checks if +self+ intersects with another +cube+.
        def intersects?(cube)
            # Cubes intersects if they do not include any 0,1 or 1,0 pattern.
            return (not @bits.each_char.with_index.find do |bit,i|
                bit != "-" and cube[i] != "-" and bit != cube[i]
            end)
        end

        ## Creates the intersection between +self+ and another +cube+.
        #
        #  Return a new cube giving the intersection, or nil if there is none.
        def intersect(cube)
            cbits = "-" * self.width
            # Cubes intersects if they do not include any 0,1 or 1,0 pattern.
            @bits.each_char.with_index do |bit,i|
                if bit == "-" then
                    cbits[i] = cube[i]
                elsif cube[i] == "-" then
                    cbits[i] = bit
                elsif bit != cube[i] then
                    # No intersection.
                    return nil
                else
                    cbits[i] = bit
                end
            end
            return Cube.new(cbits)
        end

        ## Iterates over the minterms included by the cube.
        #
        #  The minterm are represented by bit strings.
        #
        #  Returns an iterator if no block is given.
        def each_minterm
            # No block given? Return an enumerator.
            return to_enum(:each_minterm) unless block_given?

            # Block given? Apply it.
            # Locate the "-" in the bit: they are the source of alternatives
            free_cols = @bits.size.times.find_all {|i| @bits[i] == "-" }
            # Generate each possible min term
            if (free_cols.empty?) then
                # Only one minterm
                yield(@bits.clone)
            else
                # There are several minterms
                (2 ** (free_cols.size)).times do |sel|
                    # Generate the minterm corresponding combination +sel+.
                    minterm = @bits.clone
                    free_cols.each.with_index do |col,i|
                        if  (sel & (2 ** i) == 0) then
                            # The column is to 0
                            minterm[col] = "0"
                        else
                            # The column is to 1
                            minterm[col] = "1"
                        end
                    end
                    # The minterm is ready, use it.
                    yield(minterm)
                end
            end
        end
    end


    ##
    # Represents a cover of a boolean function.
    class Cover

        ## Creates a new cover on a boolean space represented by a list of 
        #  +variables+.
        def initialize(*variables)
            @variables = *variables
            # Initialize the cover
            @cubes = []
            # @sorted = false # Initialy, the cover is not sorted
        end

        ## Gets the width (the number of variables of the boolean space).
        def width
            return @variables.length
        end

        ## Gets the size (the number of cubes).
        def size
            return @cubes.size
        end

        ## Adds a +cube+ to the cover.
        #
        #  Creates a new cube if +cube+ is not an instance of LogicTools::Cube.
        def add(cube)
            # Check the cube.
            cube = Cube.new(cube) unless cube.is_a?(Cube)
            if cube.width != self.width then
                raise "Invalid cube width for #{cube}, expecting: #{self.width}"
            end
            # The cube is valid, add it.
            @cubes.push(cube)
            # # The cubes of the cover are therefore unsorted.
            # @sorted = false
        end
        alias << add

        ## Iterates over the cubes of the cover.
        #
        #  Returns an enumerator if no block is given.
        def each_cube(&blk)
            # No block given? Return an enumerator.
            return to_enum(:each_cube) unless block_given?
            # Block given? Apply it.
            @cubes.each(&blk)
        end
        alias each each_cube

        ## duplicates the cpver.
        def clone # :nodoc:
            cover = Cover.new(*@variables)
            @cubes.each { |cube| cover << cube }
            return cover
        end
        alias dup clone

        ## Iterates over the variables of the cube
        #
        #  Returns an enumberator if no block is given
        def each_variable(&blk)
            # No block given? Return an enumerator
            return to_enum(:each_variable) unless block_given?
            # Block given? Apply it.
            @variables.each(&blk)
        end

        ## Evaluates the corresponding function's value for a binary +input+.
        #
        #  +input+ is assumed to be an integer.
        #  Returns the evaluation result as a boolean.
        def eval(input)
            # Evaluates each cube, if one results in true the result is true.
            return !!@cubes.each.find {|cube| cube.eval(input) }
        end

        ## Converts to a string.
        def to_s # :nodoc:
            "#{@variables.join},#{@cubes.join(",")}"
        end

        # ## Sorts the cubes.
        # def sort!
        #     @cubes.sort! unless @sorted
        #     # Remember the cubes are sorted to avoid doing it again.
        #     @sorted = true
        #     return self
        # end

        ## Removes duplicate cubes.
        def uniq!
            @cubes.uniq!
            return self
        end

        ## Generates the cofactor obtained when +var+ is set to +val+.
        def cofactor(var,val)
            if val != "0" and val != "1" then
                raise "Invalid value for generating a cofactor: #{val}"
            end
            # Get the index of the variable.
            i = @variables.index(var)
            # Create the new cover.
            cover = Cover.new(*@variables)
            # Set its cubes.
            @cubes.each do |cube| 
                cube = cube.to_s
                # cube[i] = val # WRONG
                cube[i] = "-" if cube[i] == val
                cover << Cube.new(cube) if cube[i] == "-"
            end
            cover.uniq!
            return cover
        end

        ## Generates the generalized cofactor from +cube+.
        def cofactor_cube(cube)
            # Create the new cover.
            cover = Cover.new(*@variables)
            # Set its cubes.
            @cubes.each do |scube|
                scube = scube.to_s
                scube.size.times do |i|
                    if scube[i] == cube[i] then
                        scube[i] = "-" 
                    elsif (scube[i] != "-" and cube[i] != "-") then
                        # The cube is to remove from the cover.
                        scube = nil
                        break
                    end
                end
                if scube then
                    # The cube is to keep in the cofactor.
                    cover << Cube.new(scube)
                end
            end
            cover.uniq!
            return cover
        end

        ## Looks for a binate variable.
        #  
        #  Returns the found binate variable or nil if not found.
        #
        #  NOTE: Can also be used for checking if the cover is unate.
        def find_binate
            # Merge the cube over one another until a 1 over 0 or 0 over 1
            # is met.
            # The merging rules are to followings:
            # 1 over 1 => 1
            # 1 over - => 1
            # 1 over 0 => not unate
            # 0 over 0 => 0
            # 0 over - => 0
            # 0 over 1 => not unate
            merge = "-" * self.width
            @cubes.each do |cube|
                cube.each.with_index do |bit,i|
                    if bit == "1" then
                        if merge[i] == "0" then
                            # A 1 over 0 is found, a binate variable is found.
                            return @variables[i]
                        else
                            merge[i] = "1"
                        end
                    elsif bit == "0" then
                        if merge[i] == "1" then
                            # A 0 over 1 is found, a binate variable is found.
                            return @variables[i]
                        else
                            merge[i] = "0"
                        end
                    end
                end
            end
            # The cover is unate: no binate variable.
            return nil
        end

        
        ## Creates the union of self and +cover+.
        #
        #  +cover+ is either an instance of LogicTools::Cover or
        #  a single instance of LogicTools::Cube.
        def unite(cover)
            # Check if the covers are compatible.
            if (cover.width != self.width) then
                raise "Incompatible cover for union: #{cover}"
            end
            # Creates the union cover.
            union = Cover.new(*@variables)
            # Fill it with the cubes of self and +cover+.
            @cubes.each { |cube| union.add(cube.clone) }
            if cover.is_a?(Cover) then
                cover.each_cube { |cube| union.add(cube.clone) }
            elsif cover.is_a?(Cube) then
                union.add(cover.clone)
            else
                raise "Invalid class for cover union: #{cover.class}"
            end
            # Return the result.
            return union
        end
        alias + unite

        ## Creates the subtraction from +self+ minus one +cover+.
        #
        #  +cover+ is either an instance of LogicTools::Cover or
        #  a single instance of LogicTools::Cube.
        def subtract(cover)
            # Check if the covers are compatible.
            if (cover.width != self.width) then
                raise "Incompatible cover for union: #{cover}"
            end
            # Creates the substraction cover.
            subtraction = Cover.new(*@variables)
            if cover.is_a?(Cube) then
                cover = [cover]
            elsif !(cover.is_a?(Cover)) then
                raise "Invalid class for cover union: #{cover.class}"
            end
            @cubes.each do |cube|
                subtraction << cube unless cover.each.include?(cube)
            end
            # Return the result.
            return subtraction
        end
        alias - subtract

        ## Generates the complement cover.
        def complement
            # First treat the case when the cover is empty:
            # the result is the tautology.
            if @cubes.empty? then
                result = Cover.new(*@variables)
                result << Cube.new("-"*self.width)
                return result
            end
            # Otherwise...
            
            # Look for a binate variable to split on.
            binate = self.find_binate
            unless binate then
                # The cover is actually unate, complement it the fast way.
                # Step 1: Generate the following boolean matrix:
                # each "0" and "1" is transformed to "1"
                # each "-" is transformed to "0"
                matrix = []
                @cubes.each do |cube|
                    line = " " * self.width
                    matrix << line
                    cube.each.with_index do |bit,i|
                        line[i] = (bit == "0" or bit == "1") ? "1" : "0"
                    end
                end
                # Step 2: finds all the minimal column covers of the matrix
                mins = minimal_column_covers(matrix)
                # Step 3: generates the complent cover from the minimal
                # column covers.
                # Each minimal column cover is converted to a cube using
                # the following rules (only valid because the initial cover
                # is unate):
                # * a minimal column whose variable can be reduced to 1
                #   is converted to the not of the variable
                # * a minimal column whose variable can be reduced to 0 is
                #   converted to the variable
                #
                # +result+ is the final complement cover.
                result = Cover.new(*@variables)
                mins.each do |min|
                    # +cbits+ is the bit string describing the cube built
                    # from the column cover +min+.
                    cbits = "-" * self.width
                    min.each do |col|
                        if @cubes.find {|cube| cube[col] == "1" } then
                            cbits[col] = "0"
                        else
                            cbits[col] = "1"
                        end
                    end
                    result << Cube.new(cbits)      
                end
                return result
            else
                # Compute the cofactors over the binate variables.
                cf0 = self.cofactor(binate,"0")
                cf1 = self.cofactor(binate,"1")
                # Complement them.
                cf0 = cf0.complement
                cf1 = cf1.complement
                # Build the resulting complement cover as:
                # (cf0 and (not binate)) or (cf1 and binate)
                result = Cover.new(*@variables)
                # Get the index of the binate variable.
                i = @variables.index(binate)
                cf0.each_cube do |cube| # cf0 and (not binate)
                    if cube[i] != "1" then
                        # Cube's binate is not "1" so the cube can be kept
                        cube[i] = "0"
                        result << cube
                    end
                end
                cf1.each_cube do |cube| # cf1 and binate
                    if cube[i] != "0" then
                        # Cube's binate is not "0" so the cube can be kept
                        cube[i] = "1"
                        result << cube
                    end
                end
                return result
            end
        end


        ## Checks if self is a tautology.
        def is_tautology?
            # Look for a binate variable to split on.
            binate = self.find_binate
            # Gets its index
            i = @variables.index(binate)
            unless binate then
                # The cover is actually unate, check it the fast way.
                # Does it contain a "-" only cube? If yes, this is a tautology.
                @cubes.each do |cube|
                    return true unless cube.each_bit.find { |bit| bit != "-" }
                end
                # No "-" only cube, this is not a tautology
                return false
                #
                # Other techniques: actually general, not necessarily on
                # unate cover! Therefore WRONG place!
                # The cover is actually unate, check it the fast way.
                # Does it contain a "-" only cube? If yes, this is a tautology.
                # @cubes.each do |cube|
                #     return true unless cube.each_bit.find { |bit| bit != "-" }
                # end
                # # Is there a "1" only or "0" only column? If yes, this is not
                # # a tautology.
                # self.width.times do |col|
                #     fbit = @cubes[0][col]
                #     next if fbit == "-"
                #     next if (1..(@cubes.size-1)).each.find do |bit|
                #         bit != fbit
                #     end
                #     return false # Not a tautology.
                # end
                # # Check the upper bound of the number of minterms:
                # # if < 2**width, not a tautology.
                # num_minterms = 0
                # @cubes.each do |cube|
                #     num_minterms += 2 ** cube.each_bit.count {|b| b == "-"}
                # end
                # return false if num_minterms < 2**self.width
                # # Last check: the truth table.
                # (2**self.width).times do |input|
                #     return false if self.eval(input) == 0
                # end
            else
                # Compute the cofactors over the binate variables.
                cf0 = self.cofactor(binate,"0")
                cf1 = self.cofactor(binate,"1")
                # Check both: if there are tautologies, self is also a
                # tautology
                return ( cf0.is_tautology? and cf1.is_tautology? )
            end
        end


        ## Creates the smallest cube containing +self+.
        def smallest_containing_cube
            # Create a new cube including "-" unless the columns of
            # all the columns are identical.
            cbits = "-" * self.width
            self.width.times do |i|
                cbits[i] = @cubes.reduce(nil) do |bit,cube|
                    if bit == nil then
                        bit = cube[i]
                    elsif bit != cube[i]
                        bit = "-"
                        next bit
                    end
                end
            end
            return Cube.new(cbits)
        end


        ## Checks if +self+ intersects with +cube_or_cover+.
        #
        #  +cube_or_cover+ is either a full LogicTools::Cover object or a single
        #  cube object (LogicTools::Cube or bit string).
        def intersects?(cube_or_cover)
            if cube_or_cover.is_a?(Cover) then
                # Cover case: check intersect with each cube of +cube_or_cover+.
                #
                # NOTE: !! is for converting the result to boolean.
                return !!( cube_or_cover.each_cube.find do |cube|
                    self.intersects?(cube)
                end ) 
            else
                # Cube case.
                #
                # NOTE: !! is for converting the result to boolean.
                return !!( @cubes.find do |cube|
                    cube.intersects?(cube_or_cover)
                end ) 
            end
        end
    end

end