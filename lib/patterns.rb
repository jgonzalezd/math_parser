module Patterns
  SIGNED_INTS   = /[\-\+]?[0-9]+/
  SIGNED_FLOATS = /[\-\+]? [0-9]+ ((e[\-\+]?[0-9]+)| (\.[0-9]+(e[\-\+]?[0-9]+)?))/x
  LATEX_DIV     = /\\frac\s*(?<num>\{(?:(?>[^{}])|\g<num>)*\})\s*(?<denom>\{(?:(?>[^{}])|\g<denom>)*\})/
  LATEX_MULT    = /\*|\\times|\\cdot/
  LATEX_SQRT     = /\\sqrt\s*(?<deg>\[(?:(?>[^\[\]])|\g<deg>)*\])?\s*(?<rad>\{(?:(?>[^{}])|\g<rad>)*\})/
  LATEX_OPEN    = /\(|\{|\\left\(/
  LATEX_CLOSE   = /\)|\}|\\right\)/
  IMPLICIT_MULT = /([a-z0-9]+(?>_[a-z0-9]+)?)/i
  POWER_OP      = /\^/
  PLUS_OP       = /\+/
  DIV_OP        = /\//
  SUBTR_OP      = /-/
  SQRT_OP       = /sqrt/
end
