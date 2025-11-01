param location string
param serverName string
param administratorLogin string
@secure()
param administratorLoginPassword string

// VNet / Subnet Parameter
param vnetId string
param subnetName string
param privateDnsZoneArmResourceId string

param serverEdition string = 'GeneralPurpose'
param skuSizeGB int = 128
param dbInstanceType string = 'Standard_D4ds_v4'
param version string = '14'

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: serverName
  location: location
  sku: {
    name: dbInstanceType
    tier: serverEdition
  }
  properties: {
    version: version
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    network: {
      delegatedSubnetResourceId: '${vnetId}/subnets/${subnetName}'
      privateDnsZoneArmResourceId: privateDnsZoneArmResourceId
      publicNetworkAccess: 'Disabled'
    }
    storage: {
      storageSizeGB: skuSizeGB
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    availabilityZone: '1'
  }
}

output postgresHost string = '${serverName}.postgres.database.azure.com'
output postgresPrivateDnsZoneId string = privateDnsZoneArmResourceId

// -------------------------
// Private Endpoint für LiteLLM
// -------------------------
resource postgresPE 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${serverName}-pe'
  location: location
  properties: {
    subnet: {
      id: '${vnetId}/subnets/${subnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: '${serverName}-connection'
        properties: {
          privateLinkServiceId: postgresServer.id
          groupIds: [
            'postgresqlServer'
          ]
          requestMessage: 'Auto-approved for LiteLLM container'
        }
      }
    ]
  }
}
