require 'spec_helper'

describe Parser do
  describe '#parse' do
    context 'simple arithmetic' do
      it 'parses -2+3' do
        expect(Parser.new("-2+3").parse)
        .to eq [2, :uminus, 3, :plus]
      end
      it 'parses 3+2+1+0' do
        expect(Parser.new("3+2+1+0").parse)
        .to eq [3, 2, :plus, 1, :plus, 0, :plus]
      end

      it 'parses 3-2-6+10' do
        expect(Parser.new("3-2-6+10").parse)
        .to eq [3, 2, :minus, 6, :minus, 10, :plus]
      end

      it 'parses 3-2-6+355' do
        expect(Parser.new("3-2-6+355").parse)
        .to eq [3, 2, :minus, 6, :minus, 355, :plus]
      end

      it 'parses 3^2' do
        expect(Parser.new("3^2").parse)
        .to eq [3, 2, :exp]
      end

      it 'parses 3^23' do
        #this is intended as LaTeX
        # interprets the string in the same way.
        expect(Parser.new('3^23').parse)
        .to eq [3,2,:exp,3,:mul]
      end

      context 'respects operator precedence' do
        it 'parses 3-2*5' do
          expect(Parser.new("3-2*5").parse)
          .to eq [3, 2, 5, :mul, :minus]
        end

        it 'parses 10-2*3+1' do
          expect(Parser.new("10-2*3+1").parse)
          .to eq [10, 2, 3, :mul, :minus, 1, :plus]
        end

        it 'parses 1+2+8*3*6' do
          expect(Parser.new("1+2+8*3*6").parse)
          .to eq [1, 2, :plus, 8, 3, :mul, 6, :mul, :plus]
        end

        it 'parses 1+2*3^2' do
          expect(Parser.new("1+2*3^2").parse)
          .to eq [1,2,3,2,:exp,:mul,:plus]
        end

        it 'parses 1+2/2' do
          expect(Parser.new("1+2/2").parse)
          .to eq [1,2,2,:div,:plus]
        end


      end
    end

    context 'prioritizes parentheses' do
      it 'parses (2+8)*3' do
        expect(Parser.new("(2+8)*3").parse)
        .to eq [2, 8, :plus, 3, :mul]
      end

      it 'parses (1+3)^((2+1)*3)' do
        expect(Parser.new("(1+3)^((2+1)*3)").parse)
        .to eq [1,3,:plus,2,1,:plus,3,:mul,:exp]
      end
    end

    context 'parses expressions grouped by brackets' do
      it 'parses (a^{2+x})^4' do
        expect(Parser.new("(a^{2+x})^4").parse)
        .to eq ['a',2,'x', :plus,:exp,4,:exp]
      end

      it 'objectifies (2x)^{34}' do
        expect(Parser.new("(2x)^{34}").parse)
        .to eq [2,'x', :mul, 34,:exp]
      end

      it 'objectifies \frac{a}{d}{8+x}' do
        expect(Parser.new('\frac{a}{d}{8+x}').parse)
        .to eq ['a', 'd', :div, 8, 'x', :plus, :mul]
      end
    end

    context 'variable handling' do
      it 'parses -2+a' do
        expect(Parser.new("-2+a").parse)
        .to eq [2,:uminus, 'a', :plus]
      end

      it 'parses a+b+c+d' do
        expect(Parser.new("a+b+c+d").parse)
        .to eq ['a','b',:plus, 'c', :plus, 'd', :plus]
      end

      it 'parses ((a+b)*c)^(5*3)/d' do
        expect(Parser.new("((a+b)*c)^(5*3)/d").parse)
        .to eq ["a", "b", :plus, "c", :mul, 5, 3, :mul, :exp, "d", :div]
      end

      context 'implicit multiplication' do
        it 'parses ab' do
          expect(Parser.new("ab").parse)
          .to eq ['a', 'b', :mul]
        end

        it 'parses abc' do
          expect(Parser.new("abc").parse)
          .to eq ['a', 'b', :mul, 'c', :mul]
        end

        it 'parses 2ab' do
          expect(Parser.new("2ab").parse)
          .to eq [2, 'a', :mul, 'b', :mul]
        end

        it 'parses 2*ab' do
          expect(Parser.new("2ab").parse)
          .to eq [2, 'a', :mul, 'b', :mul]
        end

        it 'parses 2*a*b' do
          expect(Parser.new("2*a*b").parse)
          .to eq [2, 'a', :mul, 'b', :mul]
        end

        it 'parses -2ay' do
          expect(Parser.new("-2ay").parse)
          .to eq [2, :uminus,'a', :mul, 'y', :mul]
        end

        it 'parses uz24jk78k9' do
          expect(Parser.new("uz24jk78k9").parse)
          .to eq ['u','z',:mul,24,:mul,'j',:mul,'k',:mul,78,:mul,'k',:mul,9,:mul]
        end

        it 'parses a(b)' do
          expect(Parser.new("a(b)").parse)
          .to eq ['a','b',:mul]
        end

        it 'parses a(bc)' do
          expect(Parser.new("a(bc)").parse)
          .to eq ['a','b','c',:mul,:mul]
        end

      end
    end

    context 'LaTeX comands' do
      context 'division' do
        it 'parses \frac{-14}{25}' do
          expect(Parser.new('\frac{14}{25}').parse)
          .to eq [14,25, :div]
        end

        it 'parses \frac{-14}{25}' do
          expect(Parser.new('\frac{-14}{25}').parse)
          .to eq [14,:uminus, 25, :div]
        end

        it 'parses \frac{14}{-25}' do
          expect(Parser.new('\frac{14}{-25}').parse)
          .to eq [14, 25, :uminus, :div]
        end

        context 'with variables' do
          it 'parses \frac{14x}{-25x}' do
            expect(Parser.new('\frac{14x}{-25x}').parse)
            .to eq [14, "x", :mul, 25, :uminus, "x", :mul, :div]
          end

          it 'parses \frac{-14a}{2+x}' do
            expect(Parser.new('\frac{-14a}{2+x}').parse)
            .to eq [14, :uminus, "a", :mul, 2, "x", :plus, :div]
          end


        end
      end
      context 'multiplication' do
        context 'with variables' do
          it 'parses \frac{14x}{x}' do
            expect(Parser.new('\frac{14x}{x}').parse)
            .to eq [14, 'x', :mul, 'x', :div]
          end

          it 'parses \frac{a+2}{-d}' do
            expect(Parser.new('\frac{a+2}{-d}').parse)
            .to eq ['a', 2, :plus, 'd', :uminus, :div]
          end
        end
      end
    end

    context 'handles complex expressions' do
      it 'parses \frac{21a+3}{\frac{-14a}{2+x}-(b+d)}' do
        expect(Parser.new('\frac{21a+3}{\frac{-14a}{2+x}-(b+d)}').parse)
        .to eq [21, "a", :mul, 3, :plus, 14, :uminus, "a", :mul, 2, "x", :plus, :div, "b", "d", :plus, :minus, :div]
      end

      it 'parses (3(x+\frac{3\frac{3}{x}+5}{4+5+a})+4)^{2(x+\frac{3}{y})w}' do
        expect(Parser.new('(3(x+\frac{3\frac{3}{x}+5}{4+5+a})+4) ^ {2 (x+\frac{3}{y}) w}').parse)
        .to eq [3, "x", 3, 3, "x", :div,:mul, 5, :plus, 4, 5, :plus, "a", :plus, :div, :plus, :mul, 4, :plus, 2, "x", 3, "y", :div, :plus, "w", :mul, :mul, :exp]
      end

      it 'parses \frac{21a+3}{4-(2(x+\frac{3}{y})w+d)}' do
        expect(Parser.new('\frac{21a+3}{4-(2(x+\frac{3}{y})w+d)}').parse)
        .to eq [21, "a", :mul, 3, :plus, 4, 2, "x", 3, "y", :div, :plus, "w", :mul, :mul, "d", :plus, :minus, :div]
      end

      it 'parses \frac{21a+3}{\frac{-14a}{2(x+\frac{3}{y})w+x}-(b+d)}' do
        expect(Parser.new('\frac{21a+3}{\frac{-14a}{2(x+\frac{3}{y})w+x}-(b+d)}').parse)
        .to eq [21, "a", :mul, 3, :plus, 14, :uminus, "a", :mul, 2, "x", 3, "y", :div, :plus, "w", :mul, :mul, "x", :plus, :div, "b", "d", :plus, :minus, :div]
      end
    end

    context 'handles floats' do
      describe 'do simple arithmetic' do
        it 'parses -1.5 + a' do
          expect(Parser.new('-1.5 + a').parse)
          .to eq [1.5, :uminus ,'a', :plus]
        end

        it 'parses 3.8 + 2.0 + 1.82 + 0.0005' do
          expect(Parser.new("3.8 + 2.0 + 1.82 + 0.0005").parse)
          .to eq [3.8, 2.0, :plus, 1.82, :plus, 0.0005, :plus]
        end

        it 'parses 3.5-2.3-6.9999+10.1245789' do
          expect(Parser.new("3.5-2.3-6.9999+10.1245789").parse)
          .to eq [3.5, 2.3, :minus, 6.9999, :minus, 10.1245789, :plus]
        end

        it 'parses 3^2' do
          expect(Parser.new("3.0009^2.11125").parse)
          .to eq [3.0009, 2.11125, :exp]
        end
      end
    end

  end
end
