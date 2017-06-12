require 'spec_helper'

describe Factory do
  let(:including_class) { Class.new {include Factory} }

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

      context 'collapsing Addition operations' do
        it 'collapses add(Addition.new(2,3), Addition.new("b", "d"))' do
          expect(add(Addition.new(2,3), Addition.new('b', 'd')))
          .to eq Addition.new(2,3,'b','d')
        end

        it 'collapses add(Addition.new(2,3), "b")' do
          expect(add(Addition.new(2,3), 'b'))
          .to eq Addition.new(2,3,'b')
        end
      end
    end

    context 'complex operations' do

      it 'can do nested operations inside multiplication' do
        expected_operations = mtp(-1, add(mtp(2,add('x',div(3,'y')),'w'),'d'))
        expect(expected_operations)
        .to eq Multiplication.new(
              -1, Addition.new(
                                Multiplication.new(
                                  2, Addition.new(
                                                  'x',
                                                  Division.new(3,'y')),
                                                  'w'
                                  ),
                                'd'))
      end
    end
  end
end
