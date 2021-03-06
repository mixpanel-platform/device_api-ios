require 'device_api/execution'
require 'device_api/ios/signing'
require 'ox'

# DeviceAPI - an interface to allow for automation of devices
module DeviceAPI
  # iOS component of DeviceAPI
  module IOS
    # Namespace for all methods encapsulating plistutil calls
    class Plistutil < Execution

      # Check to ensure that plistutil is available
      # @return [Boolean] true if plistutil is available, false otherwise
      def self.plistutil_available?
        result = execute('which plistutil')
        result.exit == 0
      end

      # Gets properties from the IPA and returns them in a hash
      # @param [String] path path to the IPA/App
      # @return [Hash] list of properties from the app
      def self.get_bundle_id_from_app(path)
        path = Signing.unpack_ipa(path) if Signing.is_ipa?(path)
        get_bundle_id_from_plist("#{path}/Info.plist")
      end

      # Gets properties from the IPA and returns them in a hash
      # @param [String] plist path to the plist
      # @return [Hash] list of properties from the app
      def self.get_bundle_id_from_plist(plist)
        raise PlistutilCommandError.new('plistutil not found') unless plistutil_available?
        result = execute("plistutil -i #{plist}")
        raise PlistutilCommandError.new(result.stderr) if result.exit != 0
        info = Ox.parse(result.stdout)
        nodes = info.locate('*/dict')
        values = {}
        last_key = nil
        nodes.each do |node|
          node.nodes.each do |child|
            if child.value == 'key'
              last_key = child.nodes.first
            elsif child.value == 'string'
              values[last_key] = child.nodes.first
            end
          end
        end
        values
      end
    end

    # plistutil error class
    class PlistutilCommandError < StandardError
      def initialize(msg)
        super(msg)
      end
    end
  end
end