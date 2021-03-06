###################################################################
# Logic tree classes extension for simplifying a logic expression #
# using the Quine-Mc Cluskey method                               #
###################################################################


require 'set'

require "logic_tools/logictree.rb"
require "logic_tools/minimal_column_covers.rb"

module LogicTools


    ##
    # Represents a logic implicant.
    class Implicant
        include Enumerable

        ## The positions of the *X* in the implicant.
        attr_reader :mask
        ## The bit vector of the implicant.
        attr_reader :bits
        ## The number of *1* of the implicant.
        attr_reader :count
        ## The bit values covered by the implicant.
        attr_reader :covers
        ## Tell if the implicant is prime or not.
        attr_reader :prime
        ## The variable associated with the implicant
        #  Do not interfer at all with the class, so
        #  public and fully accessible
        attr_accessor :var

        protected
        attr_writer :covers
        public

        ## Creates a new implicant from +base+.
        #
        #  Argument +base+ can be either another implicant or a bit string.
        def initialize(base)
            if base.is_a?(Implicant)
                @covers = base.covers.dup
                @bits = base.bits.dup
                @mask = base.mask.dup
                @count = base.count
            else
                @bits = base.to_s
                unless @bits.match(/^[01]*$/)
                    raise "Invalid bit string for an initial implicant: "+ @bits
                end
                @mask = " " * @bits.size
                @count = @bits.count("1")
                @covers = [ @bits ]
            end
            @prime = true # By default assumed prime
        end

        ## Converts to a string.
        def to_s # :nodoc:
            @bits
        end

        def inspect # :nodoc:
            @bits.dup
        end

        ## Sets the prime status to +st+ (true or false).
        def prime=(st)
            @prime = st ? true : false
        end

        ## Iterates over the bits of the implicant.
        #
        #  Returns an enumerator if no block given.
        def each(&blk)
            # No block given? Returns an enumerator
            return to_enum(:each) unless block_given?

            # Block given? Applies it on each bit.
            @bits.each_char(&blk)
        end

        ## Compares with +implicant+
        def ==(implicant) # :nodoc:
            @bits == implicant.to_s
        end
        def <=>(implicant) #:nodoc:
            @bits <=> implicant.to_s
        end

        ## duplicates the implicant.
        def dup # :nodoc:
            Implicant.new(self)
        end

        ## Gets the value of bit +i+.
        def [](i)
            @bits[i]
        end

        ## Sets the value of bit +i+ to +b+.
        def []=(i,b)
            raise "Invalid bit value: #{b}" unless ["0","1","x"].include?(b)
            return if @bits[i] == b # Already set
            # Update count and mask
            @count -= 1 if @bits[i] == "1"    # One 1 less
            @count += 1 if b == "1"           # One 1 more
            @mask[i] = " " if @bits[i] == "x" # One x less
            @mask[i] = "x" if b == "x"        # One x more
            # Update the bit string
            @bits[i] = b
        end


        ## Creates a new implicant merging current implicant with +imp+.
        def merge(implicant)
            # Has implicant the same mask?
            return nil unless implicant.mask == @mask
            # First look for a 1-0 or 0-1 difference
            found = nil
            @bits.each_char.with_index do |b0,i|
                b1 = implicant.bits[i]
                # Bits are different
                if (b0 != b1) then
                    # Stop if there where already a difference
                    if (found)
                        found = nil
                        break
                    end
                    # A 0-1 or a 1-0 difference is found
                    found = i
                end
            end
            # Can merge at bit found
            if found then
                # print "merge!\n"
                # Duplicate current implicant
                merged = self.dup
                # And update its x
                merged[found] = "x"
                # Finally update its covers
                merged.covers = @covers | implicant.covers
                return merged
            end
            # No merge
            return nil
        end
    end


    ##
    # Represents a group of implicants with only singletons, sortable
    # by number of ones.
    class SameXImplicants
        include Enumerable

        ## Creates a group of implicants.
        def initialize
            @implicants = []
            @singletons =  Set.new # Set used for ensuring each implicant is
                                   # present only once in the group
        end

        ## Gets the number of implicants of the group.
        def size
            @implicants.size
        end

        ## Iterates over the implicants of the group.
        def each(&blk)
            @implicants.each(&blk)
        end

        ## Gets implicant +i+.
        def [](i)
            @implicants[i]
        end

        ## Adds +implicant+ to the group.
        def add(implicant)
            # Nothing to do if +implicant+ is already present.
            return if @singletons.include?(implicant.bits)
            @implicants << implicant
            @singletons.add(implicant.bits.dup)
        end

        alias :<< :add

        ## Sort the implicants by number of ones.
        def sort!
            @implicants.sort_by! {|implicant| implicant.count }
        end

        ## Converts to a string
        def to_s # :nodoc:
            @implicants.to_s
        end

        def inspect # :nodoc:
            to_s
        end
    end

    # ##
    # #  Describes a pseudo variable associated to an implicant.
    # #
    # #  Used for the Petrick's method.
    # class VarImp < Variable
    #     @@base = 0 # The index of the VarImp for building the variable names

    #     ## The implicant the pseudo variable is associated to.
    #     attr_reader :implicant

    #     ## Creates a pseudo variable assoctiated to an +implicant+.
    #     def initialize(implicant)
    #         # Create the name of the variable
    #         name = nil
    #         begin
    #             name = "P" + @@base.to_s
    #             @@base += 1
    #         end while Variable.exists?(name)
    #         # Create the variable
    #         super(name)
    #         # Associate it with the implicant
    #         @implicant = implicant
    #         implicant.var = self
    #     end
    # end



    #--
    # Enhances the Node class with expression simplifying.
    #++
    class Node

    ## Converts the array of variables +var+ to a bit vector according to
    #  their values.
    def vars2int(vars)
        res = ""
        vars.each_with_index do |var,i|
            res[i] = var.value ? "1" : "0"
        end
        res
    end


    ## Computes the minimal column covers of a boolean +matrix+.
    #
    #  If +smallest+ is set to one, the method returns the smallest minimal
    #  column cover instead.
    #
    #  The +matrix+ is assumed to be an array of string, each string
    #  representing a boolean row ("0" for false and "1" for true).
    def minimal_column_covers(matrix, smallest = false,
                              deadline = Float::INFINITY)
        # print "matrix=#{matrix}\n"

        # Step 1: reduce the matrix for faster processing.
        # First put appart the essential columns.
        essentials = []
        matrix.each do |row|
            col = nil
            row.each_byte.with_index do |c,i|
                # if c == "1" then
                if c == 49 then
                    if col then
                        # The row has several "1", no essential column there.
                        col = nil
                        break
                    end
                    col = i
                end
            end
            # An essential column is found.
            essentials << col if col
        end
        essentials.uniq!
        # print "essentials = #{essentials}\n"
        # The remove the rows covered by essential columns.
        keep = [ true ] * matrix.size
        essentials.each do |col|
            matrix.each.with_index do |row,i|
                # keep[i] = false if row[col] == "1"
                keep[i] = false if row.getbyte(col) == 49
            end
        end
        # print "keep = #{keep}\n"
        reduced = matrix.select.with_index {|row,i| keep[i] }
        # print "matrix = #{matrix}\n"
        # print "reduced = #{reduced}\n"
        if reduced.empty? then
            # Essentials columns are enough for the cover, end here.
            if smallest then
                return essentials
            else
                return [ essentials ]
            end
        end

        to_optimize = false
        removed_columns = []
        begin
            to_optimize = false
            # Then remove the dominating rows
            reduced.uniq!
            reduced = reduced.select.with_index do |row0,i|
                ! reduced.find.with_index do |row1,j|
                    if i == j then
                        false
                    else
                        # The row is dominating if in includes another row.
                        res = row0.each_byte.with_index.find do |c,j|
                            # row1[j] == "1" and c == "0"
                            row1.getbyte(j) == 49 and c == 48
                        end
                        # Not dominating if res
                        !res
                    end
                end
            end

            # # Finally remove the dominated columns if only one column cover
            # # is required.
            # if smallest and reduced.size >= 1 then
            #     size = reduced[0].size
            #     size.times.reverse_each do |col0|
            #         next if removed_columns.include?(col0)
            #         size.times do |col1|
            #             next if col0 == col1
            #             # The column is dominated if it is included into another.
            #             res = reduced.find do |row|
            #                 row[col0] == "1" and row[col1] == "0"
            #             end
            #             # Not dominated if res
            #             unless res
            #                 to_optimize = true
            #                 # print "removing column=#{col0}\n"
            #                 # Dominated, remove it
            #                 reduced.each { |row| row[col0] = "0" }
            #                 removed_columns << col0
            #             end
            #         end
            #     end
            # end
        end while(to_optimize)

        # print "now reduced=#{reduced}\n"

        # Step 2: Generate the Petrick's product.
        product = []
        reduced.each do |row|
            term = []
            # Get the columns covering the row.
            row.each_byte.with_index do |bit,i|
                # term << i if bit == "1"
                term << i if bit == 49
            end
            product << term unless term.empty?
        end


        if smallest then
            if product.empty? then
                return essentials
            end
            cover = smallest_sum_term(product,deadline)
            if essentials then
                # print "essentials =#{essentials} cover=#{cover}\n"
                essentials.each {|cube| cover.unshift(cube) }
                return cover
            else
                return cover
            end
        end

        # print "product=#{product}\n"
        if product.empty? then
            sum = product
        else
            product.each {|fact| fact.sort!.uniq! }
            product.sort!.uniq!
            # print "product=#{product}\n"
            sum = to_sum_product_array(product)
            # print "sum=#{sum}\n"
            sum.each {|term| term.uniq! }
            sum.uniq!
            sum.sort_by! {|term| term.size }
            # print "sum=#{sum}\n"
        end

        # # Add the essentials to the result and return it.
        # if smallest then
        #     # print "smallest_cover=#{smallest_cover}, essentials=#{essentials}\n"
        #     return essentials if sum.empty?
        #     # Look for the smallest cover
        #     sum.sort_by! { |cover| cover.size }
        #     if essentials then
        #         return sum[0] + essentials
        #     else
        #         return sum[0]
        #     end
        # else
            sum.map! { |cover| essentials + cover }
            return sum
        # end
    end




        ## Generates an equivalent but simplified representation of the
        #  expression represented by the tree rooted by the current node.
        #
        #  Uses the Quine-Mc Cluskey method.
        def simplify
            # Step 0 checks the trivial cases.
            if self.op == :true or self.op == :false then
                return self.clone
            end

            # Step 1: get the generators

            # Gather the minterms which set the function to 1 encoded as
            # bitstrings
            minterms = []
            each_minterm do |vars|
                minterms << vars2int(vars)
            end

            # print "minterms = #{minterms}\n"

            # Create the implicant table
            implicants = Hash.new {|h,k| h[k] = SameXImplicants.new }

            # Convert the minterms to implicants without x
            minterms.each do |term|
                implicant = Implicant.new(term)
                implicants[implicant.mask] << implicant
            end

            # print "implicants = #{implicants}\n"

            # Group the adjacent implicants to obtain the generators
            size = 0
            generators = []
            # The main iterator
            has_merged = nil
            begin
                has_merged = false
                mergeds = Hash.new { |h,k| h[k] = SameXImplicants.new }
                implicants.each_value do |group|
                    group.sort! # Sort by number of one
                    size = group.size
                    # print "size = #{size}\n"
                    group.each_with_index do |implicant0,i0|
                        # print "implicant0 = #{implicant0}, i0=#{i0}\n"
                        ((i0+1)..(size-1)).each do |i1|
                            # Get the next implicant
                            implicant1 = group[i1]
                            # print "implicant1 = #{implicant1}, i1=#{i1}\n"
                            # No need to look further if the number of 1 of
                            # implicant1 is more than one larger than
                            # implicant0's
                            break if implicant1.count > implicant0.count+1
                            # Try to merge
                            mrg = implicant0.merge(implicant1)
                            # print "mrg = #{mrg}\n"
                            # Can merge
                            if mrg then
                                mergeds[mrg.mask] << mrg
                                # Indicate than a merged happend
                                has_merged = true
                                # Mark the initial generators as not prime
                                implicant0.prime = implicant1.prime = false
                            end
                        end
                        # Is the term prime?
                        if implicant0.prime then
                            # print "implicant0 is prime\n"
                            # Yes add it to the generators
                            generators << implicant0
                        end
                    end
                end
                # print "mergeds=#{mergeds}\n"
                # Prepare the next iteration
                implicants = mergeds
            end while has_merged

            # print "generators with covers:\n"
            # generators.each {|gen| print gen,": ", gen.covers,"\n" }

            # Step 2: remove the redundancies by finding the minimal column
            # sets cover from the generators.

            # # Select the generators using Petrick's method
            # # For that purpose treat the generators as variables
            # variables = generators.map {|gen| VarImp.new(gen) }
            #
            # # Group the variables by cover
            # cover2gen = Hash.new { |h,k| h[k] = [] }
            # variables.each do |var|
            #     # print "var=#{var}, implicant=#{var.implicant}, covers=#{var.implicant.covers}\n"
            #     var.implicant.covers.each { |cov| cover2gen[cov] << var }
            # end
            # # Convert this hierachical table to a product of sum
            # # First the sum terms
            # sums = cover2gen.each_value.map do |vars|
            #     # print "vars=#{vars}\n"
            #     if vars.size > 1 then
            #         NodeOr.new(*vars.map {|var| NodeVar.new(var) })
            #     else
            #         NodeVar.new(vars[0])
            #     end
            # end
            # # print "sums = #{sums.to_s}\n"
            # # Then the product
            # # expr = NodeAnd.new(*sums).uniq
            # if sums.size > 1 then
            #     expr = NodeAnd.new(*sums).reduce
            # else
            #     expr = sums[0]
            # end
            # # Convert it to a sum of product
            # # print "expr = #{expr.to_s}\n"
            # expr = expr.to_sum_product(true)
            # # print "Now expr = #{expr.to_s} (#{expr.class})\n"
            # # Select the smallest term (if several)
            # if (expr.op == :or) then
            #     smallest = expr.min_by do |term|
            #         term.op == :and ? term.size : 1
            #     end
            # else
            #     smallest = expr
            # end
            # # The corresponding implicants are the selected generators
            # if smallest.op == :and then
            #     selected = smallest.map {|term| term.variable.implicant }
            # else
            #     selected = [ smallest.variable.implicant ]
            # end

            # Creates the matrix for looking for the minimal column cover:
            # the rows stands for the covers and the columns stands for the
            # generator. A "1" indicates a cover is obtained from the
            # corresponding generator.
            matrix = []
            # Set the index table of the generators for faster lookup.
            gen2index = {}
            generators.each.with_index { |gen,i| gen2index[gen] = i }
            # Group the generators by cover
            cover2gen = Hash.new { |h,k| h[k] = [] }
            generators.each do |gen|
                # print "gen=#{gen}, covers=#{gen.covers}\n"
                gen.covers.each { |cover| cover2gen[cover] << gen }
            end
            # Fill the matrix with it.
            cover2gen.each do |cover,gens|
                # print "cover=#{cover}, gens=#{gens}\n"
                row = "0" * generators.size
                # Set the "1" (49 in byte).
                gens.each { |gen| row.setbyte(gen2index[gen],49) }
                matrix << row
            end
            # Find the minimal column cover.
            # print "matrix=#{matrix}\n"
            cols = minimal_column_covers(matrix, true)

            # Get the selected generators (implicants).
            selected = cols.map { |col| generators[col] }

            # Handle the trivial case
            if selected.empty? then
                # false case.
                return NodeFalse.new
            elsif selected.size == 1 and
                ! selected[0].each.find {|c| c == "1" or c == "0" }
                # true case
                return NodeTrue.new
            end

            # The other cases

            # Sort by variable order
            selected.sort_by! { |implicant| implicant.bits }

            # print "Selected prime implicants are: #{selected}\n"
            # Generate the resulting tree
            variables = self.get_variables()
            # First generate the prime implicants trees
            selected.map! do |prime|
                # Generate the litterals
                litterals = []
                prime.each.with_index do |c,i|
                    case c
                    when "0" then
                        litterals << NodeNot.new(NodeVar.new(variables[i]))
                    when "1" then litterals << NodeVar.new(variables[i])
                    end
                end
                # Generate the tree
                NodeAnd.new(*litterals)
            end
            # Then generate the final sum tree
            return NodeOr.new(*selected)
        end
    end
end
