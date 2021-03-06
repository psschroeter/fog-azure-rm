module Fog
  module Network
    class AzureRM
      # Subnet model for Network Security Group
      class NetworkSecurityGroup < Fog::Model
        identity :name
        attribute :id
        attribute :resource_group
        attribute :location
        attribute :network_interfaces_ids
        attribute :subnets_ids
        attribute :security_rules
        attribute :default_security_rules

        def self.parse(nsg)
          hash = {}
          hash['id'] = nsg['id']
          hash['name'] = nsg['name']
          hash['resource_group'] = nsg['id'].split('/')[4]
          hash['location'] = nsg['location']
          hash['network_interfaces_ids'] = nsg['properties']['networkInterfaces'].map { |item| item['id'] } unless nsg['properties']['networkInterfaces'].nil?
          hash['subnets_ids'] = nsg['properties']['subnets'].map { |item| item['id'] } unless nsg['properties']['subnets'].nil?
          hash['security_rules'] = []
          hash['default_security_rules'] = []

          nsg['properties']['securityRules'].each do |sr|
            security_rule = Fog::Network::AzureRM::NetworkSecurityRule.new
            hash['security_rules'] << security_rule.merge_attributes(Fog::Network::AzureRM::NetworkSecurityRule.parse(sr))
          end unless nsg['properties']['securityRules'].nil?

          nsg['properties']['defaultSecurityRules'].each do |dsr|
            security_rule = Fog::Network::AzureRM::NetworkSecurityRule.new
            hash['default_security_rules'] << security_rule.merge_attributes(Fog::Network::AzureRM::NetworkSecurityRule.parse(dsr))
          end

          hash
        end

        def save
          requires :name, :location, :resource_group

          validate_security_rules(security_rules) unless security_rules.nil?
          nsg = service.create_network_security_group(resource_group, name, location, security_rules)
          merge_attributes(Fog::Network::AzureRM::NetworkSecurityGroup.parse(nsg))
        end

        def destroy
          service.delete_network_security_group(resource_group, name)
        end

        private

        def validate_security_rules(security_rules)
          if security_rules.is_a?(Array)
            security_rules.each do |sr|
              if sr.is_a?(Hash)
                validate_security_rule_params(sr)
              else
                raise(ArgumentError, ':security_rules must be an Array of Hashes')
              end
            end
          else
            raise(ArgumentError, ':security_rules must be an Array')
          end
        end

        def validate_security_rule_params(nsr)
          required_params = [
            :name,
            :protocol,
            :source_port_range,
            :destination_port_range,
            :source_address_prefix,
            :destination_address_prefix,
            :access,
            :priority,
            :direction
          ]
          missing = required_params.select { |p| p unless nsr.key?(p) }
          if missing.length == 1
            raise(ArgumentError, "#{missing.first} is required for this operation")
          elsif missing.any?
            raise(ArgumentError, "#{missing[0...-1].join(', ')} and #{missing[-1]} are required for this operation")
          end
        end
      end
    end
  end
end
