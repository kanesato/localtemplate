// RBAC for Public IP of Application Gateway 
param appgwpipName string

// User variables
var USER_OBJECT_ID = loadJsonContent('./appgwpip-user.json', 'UserObjectId001')

// Deploy Managed IDentity (User Assigned) if needed
/*
param managedIdentityName string = 'MyUserManagedIdentity'
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}
*/

// RBAC Configuration ( default to Contributor role)
resource contributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}
resource ownerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  // Owner
  name: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
}
resource readerRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  // Reader
  name: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
}

// Reference Public IP for Application Gateway
resource appgwpip 'Microsoft.Network/publicIPAddresses@2020-05-01' existing = {
  name: appgwpipName
}

// RBAC assignment for Public IP of Application Gateway
resource roleAssignmentpipappgw 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(appgwpip.id, USER_OBJECT_ID, contributorRoleDefinition.id)
  scope: appgwpip
  properties: {
    roleDefinitionId: contributorRoleDefinition.id
    principalId: USER_OBJECT_ID
    principalType: 'User'
  }
}