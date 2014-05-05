require 'spec_helper'
require 'spectator'
require 'spectator/specs_matcher'
require 'pathname'

describe Spectator::SpecsMatcher do
  describe '#specs_for' do
    let(:config) { OpenStruct.new(Spectator.default_config_hash) }
    subject(:matcher) { described_class.new(config) }
    let(:root) { Pathname(File.expand_path('../../../', __FILE__)) }

    it 'matches specs too' do
      spec_file = Pathname(__FILE__).expand_path.relative_path_from(root).to_s

      expect(matcher.specs_for([spec_file])).to eq([spec_file])
    end
  end
end
