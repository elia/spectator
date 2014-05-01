require 'spec_helper'
require 'spectator'

# $spectator_debug = true

describe Spectator::SpecRunner do
  let(:config) { Spectator.config }
  subject(:runner) { described_class.new(config) }

  describe '#default_files' do
    it 'is spec dir' do
      expect(runner.default_files).to eq(['spec'])
    end
  end
end
