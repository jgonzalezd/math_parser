class String
  def objectify
    composer = ExpressionComposer.new(self)
    composer.compose
  end

  def is_numeric?
    (self.to_f.to_s == self || self.to_i.to_s == self)
  end
end
