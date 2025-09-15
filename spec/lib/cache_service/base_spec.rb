# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CacheService::Base, type: :model do
  let(:base_instance) { described_class.new }

  describe 'abstract methods' do
    describe '#get' do
      it 'raises NotImplementedError' do
        expect { base_instance.get('test_key') }.to raise_error(NotImplementedError, 'Subclasses must implement #get')
      end
    end

    describe '#set' do
      it 'raises NotImplementedError' do
        expect { base_instance.set('test_key', 'test_value') }.to raise_error(NotImplementedError, 'Subclasses must implement #set')
      end

      it 'raises NotImplementedError with expires_in' do
        expect { base_instance.set('test_key', 'test_value', expires_in: 3600) }.to raise_error(NotImplementedError, 'Subclasses must implement #set')
      end
    end

    describe '#delete' do
      it 'raises NotImplementedError' do
        expect { base_instance.delete([ 'test_key' ]) }.to raise_error(NotImplementedError, 'Subclasses must implement #delete')
      end
    end

    describe '#exists?' do
      it 'raises NotImplementedError' do
        expect { base_instance.exists?('test_key') }.to raise_error(NotImplementedError, 'Subclasses must implement #exists?')
      end
    end

    describe '#clear' do
      it 'raises NotImplementedError' do
        expect { base_instance.clear }.to raise_error(NotImplementedError, 'Subclasses must implement #clear')
      end
    end

    describe '#stats' do
      it 'raises NotImplementedError' do
        expect { base_instance.stats }.to raise_error(NotImplementedError, 'Subclasses must implement #stats')
      end
    end

    describe '#keys' do
      it 'raises NotImplementedError with default pattern' do
        expect { base_instance.keys }.to raise_error(NotImplementedError, 'Subclasses must implement #keys')
      end

      it 'raises NotImplementedError with custom pattern' do
        expect { base_instance.keys('test:*') }.to raise_error(NotImplementedError, 'Subclasses must implement #keys')
      end
    end
  end

  describe 'protected methods' do
    describe '#serialize' do
      it 'serializes simple values' do
        result = base_instance.send(:serialize, 'test_value')
        expect(result).to eq(Marshal.dump('test_value'))
      end

      it 'serializes complex objects' do
        complex_object = { 'key' => 'value', 'array' => [ 1, 2, 3 ] }
        result = base_instance.send(:serialize, complex_object)
        expect(result).to eq(Marshal.dump(complex_object))
      end

      it 'serializes nil values' do
        result = base_instance.send(:serialize, nil)
        expect(result).to eq(Marshal.dump(nil))
      end
    end

    describe '#deserialize' do
      it 'deserializes simple values' do
        marshaled_value = Marshal.dump('test_value')
        result = base_instance.send(:deserialize, marshaled_value)
        expect(result).to eq('test_value')
      end

      it 'deserializes complex objects' do
        complex_object = { 'key' => 'value', 'array' => [ 1, 2, 3 ] }
        marshaled_value = Marshal.dump(complex_object)
        result = base_instance.send(:deserialize, marshaled_value)
        expect(result).to eq({ 'key' => 'value', 'array' => [ 1, 2, 3 ] })
      end

      it 'deserializes null values' do
        marshaled_value = Marshal.dump(nil)
        result = base_instance.send(:deserialize, marshaled_value)
        expect(result).to be_nil
      end
    end

    describe '#normalize_expires_in' do
      it 'returns nil when expires_in is nil' do
        result = base_instance.send(:normalize_expires_in, nil)
        expect(result).to be_nil
      end

      it 'returns integer as-is' do
        result = base_instance.send(:normalize_expires_in, 3600)
        expect(result).to eq(3600)
      end

      it 'converts ActiveSupport::Duration to integer' do
        duration = 1.hour
        result = base_instance.send(:normalize_expires_in, duration)
        expect(result).to eq(3600)
      end

      it 'converts other objects to integer' do
        result = base_instance.send(:normalize_expires_in, '3600')
        expect(result).to eq(3600)
      end

      it 'converts float to integer' do
        result = base_instance.send(:normalize_expires_in, 3600.5)
        expect(result).to eq(3600)
      end
    end
  end
end
