param appName string
param location string
param vnetName string
param subnetName string
param backendPoolName string
param backendPoolAddress string
param backendPoolPort int
param frontendIpName string
param frontendIpConfigName string
param frontendPortName string
param frontendPort int
param probeName string
param probeProtocol string
param probePort int
param probeInterval int
param probeThreshold int
param ruleName string
param listenerName string
param certName string
param certData string

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: appName
  location: location
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  resourceGroup: rg
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

resource lb 'Microsoft.Network/loadBalancers@2021-02-01' = {
  name: '${appName}-lb'
  location: location
  resourceGroup: rg
  properties: {
    frontendIPConfigurations: [
      {
        name: frontendIpConfigName
        properties: {
          publicIPAddress: null
          privateIPAddress: null
          subnet: {
            id: vnet.subnets[0].id
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
        name: ruleName
        properties: {
          frontendIPConfiguration: {
            id: lb.frontendIPConfigurations[0].id
          }
          backendAddressPool: {
            id: lb.backendAddressPools[0].id
          }
          protocol: 'Tcp'
          frontendPort: frontendPort
          backendPort: backendPoolPort
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          loadDistribution: 'Default'
          probe: {
            id: lb.probes[0].id
          }
        }
      }
    ]
    probes: [
      {
        name: probeName
        properties: {
          protocol: probeProtocol
          port: probePort
          intervalInSeconds: probeInterval
          numberOfProbes: probeThreshold
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${appName}-nic'
  location: location
  resourceGroup: rg
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          subnet: {
            id: vnet.subnets[0].id
          }
          loadBalancerBackendAddressPools: [
            {
              id: lb.backendAddressPools[0].id
            }
          ]
          loadBalancerInboundNatRules: []
          privateIPAddressVersion: 'IPv4'
          primary: true
          publicIPAddress: null
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: '${appName}-vm'
  location: location
  resourceGroup: rg
  properties: {
