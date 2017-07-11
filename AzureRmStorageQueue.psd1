@{

# ID used to uniquely identify this module
GUID = 'e0485974-973b-4576-a90a-fdafda05a72d'

# Author of this module
Author = 'Paulo Marques (MSFT)'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = '© Microsoft Corporation. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Sample functions to work with Azure Storage Queues from PowerShell. It requires latest Azure PowerShell module installed, which can be downloaded from http://aka.ms/webpi-azps.'

# HelpInfo URI of this module
HelpInfoUri = ''

# Version number of this module
ModuleVersion = '1.0.0.0'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '4.0'

# Minimum version of the common language runtime (CLR) required by this module
CLRVersion = '2.0'

# Script module or binary module file associated with this manifest
#ModuleToProcess = ''

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @('AzureRmStorageQueueCoreHelper.psm1')

FunctionsToExport = @( 'Add-AzureRmStorageQueueMessage',
                        'Clear-AzureRmStorageQueue',
                        'Get-AzureRmStorageQueueQueue',
                        'Invoke-AzureRmStorageQueueGetMessage',
                        'Invoke-AzureRmStorageQueuePeekMessage',
                        'Invoke-AzureRmStorageQueuePeekMessageList',
                        'Remove-AzureRmStorageQueueMessage',
                        'Update-AzureRmStorageQueueMessage')

VariablesToExport = ''

}