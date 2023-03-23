param location string
param hubVnetName string
param spokeVnetName string
param logAnalyticsWorkspaceName string

// Azure Firewall variables
var AZFW_NAME = 'azfw-poc-main-stag-001'
var AZFW_IF_NAME = 'azfwipconf-poc-main-stag-001'
var AZFW_PIP_NAME = 'azfwpip-poc-main-stag-001'
var AZFW_SKU = 'Standard'
var TAG_VALUE = {
CostCenterNumber: '10181378'
CreateDate: '2023/03/23'
Location: 'japaneast'
Owner: 'akkoike'
}

// Default Azure Firewall Application Rule
var AZFW_DEFAULT_RULE = loadJsonContent('../default-azfw-apprule.json', 'rules')
// As you need you should uncomment this section and add your custom application rules
/*
var AZFW_APP_RULE_CUSTOM_RULES = [
  {
            name: 'hogehoge.com'
            protocols: [
                {
                    protocolType: 'Http'
                    port: 80
                }
                {
                    protocolType: 'https'
                    port: 443
                }
            ]
            fqdnTags: []
            targetFqdns: '*.hogehoge.com'
            sourceAddresses: '*'
            sourceIpGroups: []
  }
]
*/

// Default Azure Firewall Network Rule
var AZFW_DEFAULT_NETWORK_RULE = loadJsonContent('../default-azfw-nwrule.json', 'rules')

// Reference the existing Log Analytics Workspace
resource existingloganalyticsworkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' existing = {
  name: logAnalyticsWorkspaceName
}
// Reference the existing HubVNET
resource existinghubvnet 'Microsoft.Network/virtualNetworks@2020-05-01' existing = {
  name: hubVnetName
}

// Reference the existing SpokeVNET
resource existingspokevnet 'Microsoft.Network/virtualNetworks@2020-05-01' existing = {
  name: spokeVnetName
}

// Deploy public IP for Azure Firewall
resource azfwpip 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: AZFW_PIP_NAME
  location: location
  tags: TAG_VALUE
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Deploy Azure Firewall
resource azfw 'Microsoft.Network/azureFirewalls@2022-07-01' = {
  name: AZFW_NAME
  location: location
  tags: TAG_VALUE
  zones: ['1']
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: AZFW_SKU
    }
  ipConfigurations: [
    {
      name: AZFW_IF_NAME
      properties: {
        subnet: {
          id: existinghubvnet.properties.subnets[0].id
        }
        publicIPAddress: {
          id: azfwpip.id
        }
      }
    }
  ]
  applicationRuleCollections: [
    {
      name: 'default-azfw-apprule'
      properties: {
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: AZFW_DEFAULT_RULE
        //rules: concat(AZFW_DEFAULT_RULE, AZFW_APP_RULE_CUSTOM_RULES)
      }
    }
  ]
  networkRuleCollections: [
    {
      name: 'default-azfw-nwrule'
      properties: {
        priority: 100
        action: {
          type: 'Allow'
        }
        rules: AZFW_DEFAULT_NETWORK_RULE
      }
    }
  ]
  natRuleCollections: []
  }
}

// Deploy diagnostic settings for Azure Firewall
resource azfwdignosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'azfwdignosticSettings'
  scope: azfw
  properties: {
    workspaceId: existingloganalyticsworkspace.id
    logs: [
      {
        category: 'AZFWApplicationRule'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
      {
        category: 'AZFWNetworkRule'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
      {
        category: 'AZFWNatRule'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
      {
        category: 'AzureFirewallDnsProxy'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 30
        }
      }
    ]
  }
}