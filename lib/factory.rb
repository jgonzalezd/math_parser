module Factory
  include Patterns

  def add(*args)
    new_args = args_for_addition(args)
    Addition.new(*new_args)
  end

  def sbt(*args)
    first, *remaining = args.flatten
    new_args = remaining.is_a?(Array) ? remaining : [remaining]
    new_args = new_args.map { |el| el.to_s.is_numeric? ? -el : mtp(-1, el) }
    Addition.new(first, *new_args)
  end

  def mtp(*args)
    new_args = args_for_multiplication(args)
    Multiplication.new(*new_args)
  end

  def div(*args)
    Division.new(*args)
  end

  def pow(*args)
    Power.new(*args)
  end

  private

  [:multiplication, :addition].each do |op|
    op_class = Object.const_get(op.capitalize)
    allowed_classes = [Fixnum, Float, String, op_class]
    method_name = "args_for_#{op}"
    define_method method_name do |args|
      return args unless args.all? { |el| allowed_classes.include? el.class }
      args.inject([]) do |memo, el|
        # Search for nested args of the same class recursively
        # from add(a,add(b,add(c,d))) to [a, b, c, d]
        memo.concat (el.class == op_class ? self.send(method_name, el.args) : [el])
      end
    end
  end

end
