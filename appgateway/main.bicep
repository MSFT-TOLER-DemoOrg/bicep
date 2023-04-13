param rgName string
param agName string
param agPublicIpName string
param listenerName string
param certName string
param certData string
param certPassword string

resource agPublicIp 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  name: agPublicIpName
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource agSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-03-01' = {
  name: 'AppGatewaySubnet'
  properties: {
    addressPrefix: '10.0.2.0/24'
  }
}

resource ag 'Microsoft.Network/applicationGateways@2021-03-01' = {
  name: agName
  location: resourceGroup().location
  dependsOn: [
    agPublicIp
  ]
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceGroup().id + '/providers/Microsoft.Network/virtualNetworks/VNet/subnets/' + agSubnet.name
          }
          publicIPAddress: {
            id: resourceGroup().id + '/providers/Microsoft.Network/publicIPAddresses/' + agPublicIp.name
          }
        }
      }
    ]
    sslCertificates: [
      {
        name: certName
        properties: {
          data: certData
          password: certPassword
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: agPublicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
        }
      }
    ]
    httpListeners: [
      {
        name: listenerName
        properties: {
          frontendIPConfiguration: {
            id: ag.frontendIPConfigurations[0].id
          }
          frontendPort: {
            id: ag.frontendPorts[0].id
          }
          protocol: 'Https'
          sslCertificate: {
            id: ag.sslCertificates[0].id
          }
          requireServerNameIndication: true
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: ag.httpListeners[0].id
          }
          backendAddressPool: {
            id: ag.backendAddressPools[0].id
          }
          backendHttpSettings: {
            id: ag.backendHttpSettingsCollection[0].id
          }
        }
      }
    ]
    enableHttp2: true
    gatewayIPConfigurationsTextFormat: true
  }
}
