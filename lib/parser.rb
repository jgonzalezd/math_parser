require 'strscan'
# Adapted from https://github.com/avsej/calculus/blob/master/lib/calculus/parser.rb
#
# Parses string with expression or equation and builds postfix
# notation. It supprorts following operators (ordered by precedence
# from the highest to the lowest):
#
# +:sqrt+, +:exp+::   root and exponent operations. Could be written as
#                     <tt>\sqrt[degree]{radix}</tt> and <tt>x^y</tt>.
# +:div+, +:mul+::    division and multiplication. There are set of
#                     syntaxes accepted. To make division operator you
#                     can use <tt>num/denum</tt> or
#                     <tt>\frac{num}{denum}</tt>. For multiplication
#                     there accepted <tt>*</tt> and also two TeX
#                     symbols: <tt>\cdot</tt> and <tt>\times</tt>.
# +:plus+, +:minus+:: summation and substraction. Here you can use
#                     plain <tt>+</tt> and <tt>-</tt>
# +:eql+::            equals sign it has the lowest priority so it to
#                     be calculated in last turn.
#
# Also it is possible to use parentheses for grouping. There are plain
# <tt>(</tt>, <tt>)</tt> acceptable and also <tt>\(</tt>, <tt>\)</tt>
# which are differ only for latex diplay. Parser doesn't distinguish
# these two styles so you could give expression with visually
# unbalanced parentheses (matter only for image generation. Consider
# the example:
#
#   Parser.new("(2 + 3) * 4").parse   #=> [2, 3, :plus, 4, :mul]
#   Parser.new("(2 + 3\) * 4").parse  #=> [2, 3, :plus, 4, :mul]
#
# This two examples will yield the same notation, but make issue
# during display.
#
# Numbers could be given as a floats and as a integer
#
#   Parser.new("3 + 4.0 * 4.5e-10")   #=> [3, 4.0, 4.5e-10, :mul, :plus]
#
# Symbols could be just alpha-numeric values with optional subscript
# index
#
#   Parser.new("x_3 + y * E")         #=> ["x_3", "y", "E", :mul, :plus]
#
class Parser < StringScanner
  include Patterns
  attr_accessor :operators

  # Initialize parser with given source string. It could simple
  # (native expression like <tt>2 + 3 * (4 / 3)</tt>, but also in TeX
  # style <tt>2 + 3 \cdot \frac{4}{3}</tt>.
  def initialize(source)
    @operators = {:uminus => 4, :sqrt => 3, :exp => 3, :div => 2, :mul => 2, :plus => 1, :minus => 1, :eql => 0}
    super(source.dup.tr(" \n\t", ''))
  end

  # Run parse cycle. It builds postfix notation (aka reverse polish
  # notation). Returns array with operations with operands.
  #
  #   Parser.new("2 + 3 * 4").parse               #=> [2, 3, 4, :mul, :plus]
  #   Parser.new("(\frac{2}{3} + 3) * 4").parse   #=> [2, 3, :div, 3, :plus, 4, :mul]
  def parse
    exp = []
    stack = []
    token = :none
    while true
      prev, token = token, fetch_token
      case token
      when :open
        stack.push(token)
      when :close
        exp << stack.pop while operators.keys.include?(stack.last)
        stack.pop if stack.last == :open
      when :plus, :minus, :mul, :div, :exp, :sqrt, :eql
        #Dont include plus token ('+') if is a unary operator like +10
        next            if prev && (prev == :none || prev == :open)  && token == :plus
        #Transform minus token ('-') to unitary minus if is a unary operator like -10
        token = :uminus if prev && (prev == :none || prev != :close) && token == :minus
        exp << stack.pop while operators.keys.include?(stack.last) && operators[stack.last] >= operators[token]
        stack.push(token)
      when Numeric, String
        exp << token
        token = nil
      when nil
        break
      else
        raise ArgumentError, "Unexpected symbol: #{token.inspect}"
      end
    end
    exp << stack.pop while stack.last && stack.last != :open
    raise ArgumentError, "Missing closing parentheses: #{stack.join(', ')}" unless stack.empty?
    exp
  end

  # Fetch next token from source string. Skips any whitespaces
  # matching regexp <tt>/\s+/</tt> and returs <tt>nil</tt> at when
  # meet the end of string.
  #
  # Raises <tt>ParseError</tt> when encounter invalid character
  # sequence.
  def fetch_token
    skip(/\s+/)
    return nil if(eos?)
    token = nil
    scanning = true
    while(scanning)
      scanning = false
      token = case
              when scan(/=/)
                :eql
              when scan(LATEX_MULT)
                :mul
              when scan(LATEX_DIV)
                string.insert(pos, "*") if should_insert_mult?(matched)
                num, denom = [self[1], self[2]].map{|v| v.gsub(/^{|}$/, '')}
                string[pos, 0] = "{(#{num}) / (#{denom})}"
                scanning = true
              when scan(DIV_OP)
                :div
              when scan(PLUS_OP)
                :plus
              when scan(POWER_OP)
                string.insert(pos+1,"*") if /^\d+{2}/ =~ string[pos..pos+1]
                :exp
              when scan(SUBTR_OP)
                :minus
              when scan(SQRT_OP)
                :sqrt
              when scan(LATEX_SQRT)
                deg = (self[1] || "2").gsub(/^\[|\]$/, '')
                rad = self[2].gsub(/^{|}$/, '')
                string[pos, 0] = "(#{rad}) sqrt (#{deg}) "
                scanning = true
              when scan(LATEX_OPEN)
                :open
              when scan(LATEX_CLOSE)
                :close
              when scan(SIGNED_FLOATS)
                string.insert(pos,"*") if should_insert_mult?(matched)
                matched.to_f
              when scan(SIGNED_INTS)
                string.insert(pos,"*") if should_insert_mult?(matched)
                matched.to_i
              when scan(IMPLICIT_MULT)
                if matched.size > 1
                  replace matched
                  scanning = true
                  nil
                elsif should_insert_mult?(matched)
                  string.insert(pos,"*")
                  matched
                else
                  matched
                end
              else
                error_msg = "Invalid character #{string[pos]} at position #{pos} near '#{peek(20)}'."
                raise ParserError, error_msg
              end
    end#while
    return token
  end#def

  private

  # Replaces strings like "ajyxb2c" by a*j*y*x*b*2*c
  def replace(matched)
    vars = matched.split('')
    replacement = ""
    match_start_pos = pos - matched.size
    replacement << "*" if should_insert_mult?(matched)
    replacement << implicit_mult(vars)
    string[match_start_pos,matched.size] = replacement
    self.pos = match_start_pos
  end

  #generates a string like "a*j*y*x*b*2*c" from "ajyxb2c"
  def implicit_mult(elements)
    elements.inject("") do |memo, el|
      if (/[0-9|-]/ =~ el) && (/[0-9|-]/ =~ memo[-1])
        memo << el
      else
        memo << (memo.empty? ? el : "*#{el}")
      end
    end
  end

  #Decides wheather a mult. char "*" should be placed in the string or not
  def should_insert_mult?(matched)
    match_start_pos = pos - matched.size

    # true if matched char preceded by a closing token
    return true if (match_start_pos > 0) && (/[0-9\)\}]/ =~ string[match_start_pos - 1])

    #true if matched number and next is a char
    return true if matched.is_numeric? && /[a-z]/ =~ string[pos]

    # true if matched char and next is number
    return true if /[a-z]/ =~ matched && string[pos] && string[pos].is_numeric?

    # true if next char is an open parentheses
    return true if /[\(\{]/ =~ string[pos] && /[a-z0-9\)\}]/ =~ matched

    #true if next char is latex opening token
    return true if /^\\frac/ =~ string[pos..pos+4] && /[a-z0-9\)\}]/ =~ matched

    false
  end

  class ParserError < StandardError; end
end#class
