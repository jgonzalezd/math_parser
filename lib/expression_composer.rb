class ExpressionComposer
  include Factory

  attr_reader :postfix_notation, :variables

  def initialize(source)
    @postfix_notation = Parser.new(source).parse
    @variables = extract_variables
    freeze
  end

  def compose
    traverse do |operation, left, right, stack|
      raise AssigmentError if left.nil?
      case operation
      when :uminus then left.to_s.is_numeric? ? -left : mtp(-1, left)
      when :sqrt   then pow(left, 1.0/right)
      when :exp    then pow(left,     right)
      when :plus   then add(left,     right)
      when :minus  then sbt(left,     right)
      when :mul    then mtp(left,     right)
      when :div    then div(left,     right)
      end
    end
  end

private
  # Extracts variables from postfix notation and returns <tt>Hash</tt>
  # object with keys corresponding to variables and nil initial
  # values.
  def extract_variables
    postfix_notation.select{|node| node.kind_of? String}.inject({}){|h, v| h[v] = nil; h}
  end

  def traverse(&block) # yields |operation, left, right, stack|
    stack = []
    postfix_notation.each do |node|
      case node
      when Symbol
        operation, right, left = node, (node == :uminus ? nil : stack.pop), stack.pop
        stack.push(yield(operation,left, right, stack))
      when Numeric
        stack.push(node)
      when String
        stack.push(variables[node] || node)
      end
    end
    stack.first
  end
  class AssigmentError < StandardError; end
end
