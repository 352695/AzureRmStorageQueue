# AzureRmStorageQueue
PowerShell module to interact with Azure Storage Queues.

For detailed information on how to work with this PowerShell module, please refer to https://blogs.technet.microsoft.com/paulomarques/2017/08/12/working-with-azure-storage-queues-from-powershell/ .

## Changelog

### 01/10/2018
* Contribution from John O'Sullivan that implements a custom expiration time for the queued message

### 12/05/2017
* Implemented some measures in order to avoid conflicts between different assembly versions, more specifically Microsoft.WindowsAzure.Storage.Dll.

### 11/13/2017
* Add-AzureRmStorageQueueMessage cmdlet now accepts string as message type on top of hashtables
