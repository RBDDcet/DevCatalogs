targetScope = 'managementGroup'

@description('Name of the thing')
param name string = 'VanArsdelLTD'

@description('Location of the thing')
param location string = 'eastus' // This needs to stay eastus2

@description('The principal ids of users to assign the role of DevCenter Project Admin.  Users must either have DevCenter Project Admin or DevCenter Dev Box User role in order to create a Dev Box.')
param projectAdmins array = [
  '<ObjId>'
]

@description('The principal ids of users to assign the role of DevCenter Dev Box User.  Users must either have DevCenter Project Admin or DevCenter Dev Box User role in order to create a Dev Box.')
param devBoxUsers array = [
  '<ObjId>'
]

@description('The principal ids of users to assign the role of DevCenter Deployment Environments User.  Users must either have Deployment Environments User role in order to create a Environments.')
param environmentUsers array = [
  '<ObjId>'
]

// Podcast-CI
param ciPrincipalId string = '<ObjId>'

@description('Github Uri')
param githubUri string = 'https://github.com/RBDDcet/DevCatalogs.git'

//@secure()
@description('[Environments] Personal Access Token from GitHub with the repo scope')
//#disable-next-line secure-parameter-default
param githubPat string = '<not secure need to adjust>'

@description('Github Path')
param githubPath string = '/DevCenter/Catalogs'

@description('Primary subscription')
param primarySubscription string = '<SubId>'

@description('Tags to apply to the resources')
param tags object = {}

@description('[Project] An object with property keys containing the Project name and values containing Subscription and Description properties. See bicep file for example.')
param projects array = [
  {
    name: 'PNL_Alpha_DEV'
    subscriptionId: '<SubId>'
  }
  {
    name: 'PNL_Bravo_DEV'
    subscriptionId: '<SubId>'
  }
  {
    name: 'PNL_Charlie_DEV'
    subcriptionId:'<SubId>'
  }
]

@description('[Environments] An object with property keys containing the Environment Type name and values containing Subscription and Description properties. See bicep file for example.')
param environmentTypes object = {
  Dev: '<SubId>'
  Test: '<SubId>'
  Prod: '<SubId>'
}

// clean up the keyvault name an add a suffix to ensure it's unique
var keyVaultNameStart = replace(replace(replace(toLower(trim(name)), ' ', '-'), '_', '-'), '.', '-')
var keyVaultNameAlmost = length(keyVaultNameStart) <= 24 ? keyVaultNameStart : take(keyVaultNameStart, 24)
var keyVaultName = '${keyVaultNameAlmost}kvk'

var vnetNameStart = replace(toLower(trim(name)), ' ', '-')
var vnetName = '${vnetNameStart}-vnet'

var galleryName = '${keyVaultNameAlmost}gallery'

// ------------------
// Resource Groups
// ------------------

module primaryRG 'resourceGroup.bicep' = {
  scope: subscription(primarySubscription)
  name: '${name}RG'
  params: {
    #disable-next-line BCP334 BCP335
    name: '${name}RG'
    location: location
    tags: tags
  }
}

module secondRG 'resourceGroup.bicep' = {
  scope: subscription(projects[0].subscriptionId)
  name: '${projects[0].name}RG'
  params: {
    #disable-next-line BCP334 BCP335
    name: '${projects[0].name}RG'
    location: location
    tags: tags
  }
}
