module Fog
  module Network
    class AzureRM
      # Real class for Network Request
      class Real
        def delete_application_gateway(resource_group, name)
          Fog::Logger.debug "Deleting Application_Gateway #{name} from Resource Group #{resource_group}."
          begin
            promise = @network_client.application_gateways.delete(resource_group, name)
            promise.value!
            Fog::Logger.debug "Application Gateway #{name} Deleted Successfully."
            true
          rescue  MsRestAzure::AzureOperationError => e
            msg = "Exception deleting Application_Gateway #{name} in Resource Group: #{resource_group}. #{e.body['error']['message']}"
            raise msg
          end
        end
      end

      # Mock class for Network Request
      class Mock
        def delete_application_gateway(_resource_group, _name)
        end
      end
    end
  end
end
