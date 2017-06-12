module Factory
  include Patterns

  def add(*args)
    new_args = args_for_addition(args)
    Addition.new(*new_args)
  end

  def sbt(*args)
    # byebug

    first, remaining = args

    new_args = [remaining] unless remaining.is_a?(Array)
    new_args = new_args.map do |el|
      el.to_s.is_numeric? ? -el : mtp(-1, el)
    end

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
    method_name = "args_for_#{op}"
    define_method method_name do |args|
      return args unless args.all? do |el|
        [Fixnum, Float, String, Object.const_get(op.capitalize)].include? el.class
      end
      args.inject([]) do |memo, el|
        if el.class == Object.const_get(op.capitalize)
          memo.concat self.send(method_name, el.args)
        else
          memo << el
        end
      end
    end
  end

end
