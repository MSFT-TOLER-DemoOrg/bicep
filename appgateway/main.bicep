param appName string
param location string
param vnetName string
param subnetName string
param backendPoolName string
param backendPoolAddress string
param backendPoolPort int
param listenerName string
param frontendPort int
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

resource publicIp 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${appName}-pip'
  location: location
  resourceGroup: rg
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource frontendIp 'Microsoft.Network/applicationGateways/frontendIPConfigurations@2021-02-01' = {
  name: '${appName}-frontendIp'
  location: location
  resourceGroup: rg
  properties: {
    publicIPAddress: {
      id: publicIp.id
    }
  }
}

resource frontendPort 'Microsoft.Network/applicationGateways/frontendPorts@2021-02-01' = {
  name: '${appName}-frontendPort'
  location: location
  resourceGroup: rg
  properties: {
    port: frontendPort
  }
}

resource cert 'Microsoft.Network/applicationGateways/sslCertificates@2021-02-01' = {
  name: '${appName}-cert'
  location: location
  resourceGroup: rg
  properties: {
    data: certData
    password: ''
  }
}

resource backendPool 'Microsoft.Network/applicationGateways/backendAddressPools@2021-02-01' = {
  name: backendPoolName
  location: location
  resourceGroup: rg
}

resource backendAddress 'Microsoft.Network/applicationGateways/backendAddressPools/backendAddresses@2021-02-01' = {
  name: '${backendPoolName}-address'
  location: location
  resourceGroup: rg
  properties: {
    ipAddress: backendPoolAddress
  }
  dependsOn: [
    backendPool
  ]
}

resource httpSettings 'Microsoft.Network/applicationGateways/backendHttpSettingsCollection@2021-02-01' = {
  name: '${appName}-httpSettings'
  location: location
  resourceGroup: rg
  properties: {
    port: backendPoolPort
    protocol: 'Https'
    cookieBasedAffinity: 'Disabled'
    pickHostNameFromBackendAddress: true
    requestTimeout: 20
    probeEnabled: true
    probe: {
      protocol: 'Https'
      path: '/grpc.health.v1.Health/Check'
      interval: 30
      timeout: 30
      unhealthyThreshold: 3
      pickHostNameFromBackendHttpSettings: true
    }
  }
  dependsOn: [
    backendPool
  ]
}

resource listener 'Microsoft.Network/applicationGateways/httpListeners@2021-02-01' = {
  name: listenerName
  location: location
  resourceGroup: rg 
