require 'spec_helper'

describe Factory do
  let(:including_class) { Class.new {include Factory} }

  describe 'Simple operations' do
    describe '#add' do
      it 'handles numbers' do
        expect(add(2,4)).to eq Addition.new(2,4)
      end

      it 'handles more than two numbers' do
        expect(add(2,4,6,8)).to eq Addition.new(2,4,6,8)
      end

      it 'handles negative numbers' do
        expect(add(-2,-4)).to eq Addition.new(-2,-4)
      end

      it 'handles variables' do
        expect(add('a','b')).to eq Addition.new('a','b')
      end

      it 'handles more thant two variables' do
        expect(add('a','b', 'c','d')).to eq Addition.new('a','b','c','d')
      end

      it 'handles multiple mixed params' do
        expect(add('a',2, 'c',4)).to eq Addition.new('a',2,'c',4)
      end

      it 'handles arrays of numbers' do
        expect(add([1,2,3,4,5])).to eq Addition.new(1,2,3,4,5)
      end

      it 'handles arrays of variables' do
        expect(add(['a','b','c','d','e']))
        .to eq Addition.new('a','b','c','d','e')
      end

      it 'handles mixed arrays' do
        expect(add(['a',1,'c',4,'e']))
        .to eq Addition.new('a',1,'c',4,'e')
      end
    end

    describe '#sbt' do
      it 'handles numbers' do
        expect(sbt(2,4)).to eq Addition.new(2,-4)
      end

      it 'handles more than two numbers' do
        expect(sbt(2,4,6,8)).to eq Addition.new(2,-4,-6,-8)
      end

      it 'handles negative numbers' do
        expect(sbt(-2,-4)).to eq Addition.new(-2, 4)
      end

      it 'handles variables' do
        expect(sbt('a','b'))
        .to eq Addition.new('a',Multiplication.new(-1, 'b'))
      end

      it 'handles more thant two variables' do
        expect(sbt('a','b', 'c','d'))
        .to eq Addition.new(
                'a',
                Multiplication.new(-1, 'b'),
                Multiplication.new(-1, 'c'),
                Multiplication.new(-1, 'd'))
      end

      it 'handles multiple mixed params' do
        expect(sbt('a',2, 'c',4))
        .to eq Addition.new( 'a', -2, Multiplication.new(-1, 'c' ) , -4)
      end

      it 'handles arrays of numbers' do
        expect(sbt([1,2,3,4,5])).to eq Addition.new(1,-2,-3,-4,-5)
      end

      it 'handles arrays of variables' do
        expect(sbt(['a','b','c','d']))
        .to eq Addition.new(
            'a',
            Multiplication.new(-1, 'b'),
            Multiplication.new(-1, 'c'),
            Multiplication.new(-1, 'd'))
      end

      it 'handles mixed arrays' do
        expect(sbt(['a',1,'c',4]))
        .to eq Addition.new( 'a', -1, Multiplication.new(-1, 'c' ) , -4)
      end

      #==========================================================================
    end

    describe '#div' do
      it 'handles numbers' do
        expect(div(2,4)).to eq Division.new(2,4)
      end

      it 'handles negative numbers' do
        expect(div(-2,-4)).to eq Division.new(-2,-4)
      end

      it 'handles mixed signed numbers' do
        expect(div(-2,4)).to eq Division.new(-2,4)
      end

      it 'handles variables' do
        expect(div('a','b')).to eq Division.new('a','b')
      end

    end

    describe '#mtp' do
      it 'handles numbers' do
        expect(mtp(2,4)).to eq Multiplication.new(2,4)
      end

      it 'handles more than two numbers' do
        expect(mtp(2,4,6,8)).to eq Multiplication.new(2,4,6,8)
      end

      it 'handles negative numbers' do
        expect(mtp(-2,-4)).to eq Multiplication.new(-2,-4)
      end

      it 'handles variables' do
        expect(mtp('a','b')).to eq Multiplication.new('a','b')
      end

      it 'handles more thant two variables' do
        expect(mtp('a','b', 'c','d')).to eq Multiplication.new('a','b','c','d')
      end

      it 'handles multiple mixed params' do
        expect(mtp('a',2, 'c',4)).to eq Multiplication.new('a',2,'c',4)
      end

      it 'handles arrays of numbers' do
        expect(mtp([1,2,3,4,5])).to eq Multiplication.new(1,2,3,4,5)
      end

      it 'handles arrays of variables' do
        expect(mtp(['a','b','c','d','e']))
        .to eq Multiplication.new('a','b','c','d','e')
      end

      it 'handles mixed arrays' do
        expect(mtp(['a',1,'c',4,'e']))
        .to eq Multiplication.new('a',1,'c',4,'e')
      end
    end

    describe '#pow' do
      it 'handles numbers' do
        expect(pow(4, 3)).to eq Power.new(4,3)
      end

      it 'handles variables' do
        expect(pow('b', 'a')).to eq Power.new('b','a')
      end
    end
  end

  describe 'Nested operations' do
    context '#mtp' do

      it 'can do nested operations inside multiplication' do
        expected_ops = mtp(-1, add(mtp(2,add('x',div(3,'y')),'w'),'d'))
        expect(expected_ops)
        .to eq Multiplication.new(
              -1, Addition.new(
                    Multiplication.new( 2, Addition.new( 'x', Division.new(3,'y')), 'w' ),
                    'd'))
      end

      it 'collapses nested mtp operations with numbers' do
        expected_ops = mtp(3, mtp(4, mtp(7, 8)))
        expect(expected_ops)
        .to eq Multiplication.new(3,4,7,8)
      end

      it 'collapses nested mtp operations with variables' do
        expected_ops = mtp('a', mtp('b', mtp('c', 'd')))
        expect(expected_ops)
        .to eq Multiplication.new('a','b','c','d')
      end

      it 'can do operations with other models' do
        expected_ops = mtp('a', add('b', mtp('c', 'd')))
        expect(expected_ops)
        .to eq Multiplication.new('a', Addition.new('b', Multiplication.new('c', 'd')))
      end
    end

    context '#add' do
      describe 'collapsing' do
        it 'collapses nested add operations with numbers' do
          expected_ops = add(3, add(4, add(7, 8)))
          expect(expected_ops)
          .to eq Addition.new(3,4,7,8)
        end

        it 'collapses nested add operations with variables' do
          expected_ops = add('a', add('b', add('c', 'd')))
          expect(expected_ops)
          .to eq Addition.new('a','b','c','d')
        end

        it 'collapses add(Addition.new(2,3), Addition.new("b", "d"))' do
          expect(add(add(2,3), add('b', 'd')))
          .to eq Addition.new(2,3,'b','d')
        end

        it 'collapses add(Addition.new(2,3), "b")' do
          expect(add(add(2,3), 'b'))
          .to eq Addition.new(2,3,'b')
        end
      end


    end

    describe '#sbt' do
      context 'simple operations with models' do
        it 'substracts models using multiplication by -1 ' do
          expect(sbt(4, Addition.new('a', 'b')))
          .to eq Addition.new(4, Multiplication.new(-1, Addition.new('a', 'b')))
        end

        it 'substracts (Division, Addition)' do
          expect(sbt(Division.new(2,3), Addition.new('b', 'd')))
          .to eq Addition.new(
            Division.new(2,3),
            Multiplication.new(-1, Addition.new('b', 'd')))
        end
      end

    end

    describe '#pow' do
      it 'can nest other models' do
        expect(pow(add(2,3), mtp(2,'a')))
        .to eq Power.new(Addition.new(2,3),Multiplication.new(2,'a'))
      end

      it 'can nest the same model' do
        expect(pow(pow(2,3), pow(2,'a')))
        .to eq Power.new(Power.new(2,3), Power.new(2,'a'))
      end

    end

    describe '#div' do
      it 'can nest other models' do
        expect(pow(add(2,3), mtp(2,'a')))
        .to eq Power.new(Addition.new(2,3),Multiplication.new(2,'a'))
      end

      it 'can nest the same model' do
        expect(div(div(2,3), div(2,'a')))
        .to eq Division.new(Division.new(2,3),Division.new(2,'a'))
      end
    end
  end

end
