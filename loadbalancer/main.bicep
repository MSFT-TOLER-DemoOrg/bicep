param rgName string
param lbName string
param vnetName string
param subnetName string
param frontendIPName string
param frontendIPConfigType string = 'Private'
param frontendIPPrivateAddress string
param certName string
param certData string
param certPassword string
param backendPoolName string
param healthProbeName string
param backendPort int = 80
param protocol string = 'TCP'

resource lb 'Microsoft.Network/loadBalancers@2021-03-01' = {
  name: lbName
  location: resourceGroup().location
  properties: {
    frontendIPConfigurations: [
      {
        name: frontendIPName
        properties: {
          privateIPAddress: frontendIPPrivateAddress
          subnet: {
            id: resourceGroup().id + '/providers/Microsoft.Network/virtualNetworks/' + vnetName + '/subnets/' + subnetName
          }
          privateIPAllocationMethod: if(frontendIPConfigType == 'Private') {
            'Dynamic'
          } else {
            'Static'
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendPoolName
      }
    ]
    loadBalancingRules: [
      {
        name: 'rule1'
        properties: {
          frontendIPConfiguration: {
            id: lb.frontendIPConfigurations[0].id
          }
          backendAddressPool: {
            id: lb.backendAddressPools[0].id
          }
          protocol: protocol
          frontendPort: 443
          backendPort: backendPort
          enableFloatingIP: false
          enableTcpReset: false
          idleTimeoutInMinutes: 15
          probe: {
            id: lb.probes[0].id
          }
          disableOutboundSnat: true
          loadDistribution: 'SourceIP'
          sslCertificates: [
            {
              id: resourceGroup().id + '/providers/Microsoft.Network/loadBalancers/' + lbName + '/frontendIPConfigurations/' + frontendIPName + '/sslCertificates/' + certName
            }
          ]
        }
      }
    ]
    probes: [
      {
        name: healthProbeName
        properties: {
          protocol: protocol
          port: backendPort
          intervalInSeconds: 15
          numberOfProbes: 2
          requestPath: '/'
          protocolSettings: {
            port: backendPort
            settings: {
              sslSettings: {
                serverNameIndication: 'Enabled'
                serverCertificate: {
                  name: certName
                  data: certData
                  password: certPassword
                }
              }
            }
          }
        }
      }
    ]
  }
}
