########################################################
#     Parse a string and convert to a logic tree       #
########################################################

# For parsing the inputs
require 'parslet'

# For building logic tress
require 'logic_tools/logictree.rb'

module LogicTools
    # The parser of logic expressions. Source: http://kschiess.github.io/parslet/
    class Parser < Parslet::Parser
        # Variable
        rule(:var) { match('[0-9A-Za-z]').repeat(1) }
        # And operator
        # rule(:andop) { str("&&") | match('[&\.\*^]') }
        rule(:andop) { str(":") }
        # Or operator
        # rule(:orop) { match('[+|v]') }
        rule(:orop) { str("+") }
        # Not operator
        rule(:notop) { match('[~!]') }

        # Grammar rules
        root(:expr)
        rule(:expr) { orexpr }
        rule(:orexpr) { (andexpr >> ( orop >> andexpr ).repeat).as(:orexpr) }
        rule(:andexpr) { (notexpr >> ( (andop >> notexpr) | notexpr ).repeat).as(:andexpr) }
        rule(:notexpr) { ((notop.as(:notop)).repeat >> term).as(:notexpr) }

        rule(:term) { var.as(:var) | ( str("(") >> expr >> str(")") ) }
    end

    ## The logic tree generator from the syntax tree.
    class Transform < Parslet::Transform
        # Terminal rules
        rule(:var => simple(:var)) do
            name = var.to_s
            NodeVar.new(name)
        end
        rule(:notop => simple(:notop)) { "!" }

        # Not rules
        rule(:notexpr => simple(:expr)) { expr }
        rule(:notexpr => sequence(:seq)) do
            expr = seq.pop
            if seq.size.even? then
                expr
            else
                NodeNot.new(expr)
            end
        end

        # And rules
        rule(:andexpr => simple(:expr)) { expr }
        rule(:andexpr => sequence(:seq)) do
            NodeAnd.new(*seq)
        end

        # Or rules
        rule(:orexpr => simple(:expr)) { expr }
        rule(:orexpr => sequence(:seq)) do
            NodeOr.new(*seq)
        end
    end

    ## The parser/gerator main fuction: converts the text in +str+ to a logic tree.
    def string2logic(str)
        # Remove the spaces
        str = str.gsub(/\s+/, "")

        parsed_string = Parser.new.parse(str)
        transformed_string = Transform.new.apply(parsed_string)

        return transformed_string
    end
end
