﻿
<#
.SYNOPSIS
	AzureRmStorageQueueCoreHelper.psm1 - PowerShell Module that contains all functions related to manipulating Azure Storage Queues.
.DESCRIPTION
  	AzureRmStorageQueueCoreHelper.psm1 - PowerShell Module that contains all functions related to manipulating Azure Storage Queues.
.NOTES
	Make sure the latest Azure PowerShell module is installed since we have a dependency on Microsoft.WindowsAzure.Storage.dll and 
    Microsoft.WindowsAzure.Commands.Common.Storage.dll.

	If running this module from Azure Automation, please make sure you check out this blog post for more information:
    https://blogs.technet.microsoft.com/paulomarques/xyz
#>

#Requires -Modules AzureRM.Profile, AzureRM.Storage, AzureRM.Resources, Azure.Storage

# Module Functions

function Get-AzureRmStorageQueueQueue
{
	<#
	.SYNOPSIS
		Gets a Queue object, it can be from Azure Storage Queue.
	.DESCRIPTION
		Gets a Queue object, it can be from Azure Storage Queue.
	.PARAMETER resourceGroup
        Resource Group where the Azure Storage Account is located
    .PARAMETER queueName
        Name of the queue to retrieve
    .PARAMETER storageAccountName
        Storage Account name where the queue lives
	.EXAMPLE
		# Getting storage table object
		$resourceGroup = "myResourceGroup"
		$storageAccount = "myStorageAccountName"
		$queueName = "queue01"
		$queue = Get-AzureStorageQueueQueue -resourceGroup $resourceGroup -queueName $queueName -storageAccountName $storageAccount
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(ParameterSetName="AzureRmQueueStorage",Mandatory=$true)]
		[string]$resourceGroup,
		
		[Parameter(Mandatory=$true)]
        [String]$queueName,

		[Parameter(ParameterSetName="AzureRmQueueStorage",Mandatory=$true)]
		[Parameter(ParameterSetName="AzureQueueStorage",Mandatory=$true)]
        [String]$storageAccountName
	)

    $nullQueueErrorMessage = [string]::Empty

    switch ($PSCmdlet.ParameterSetName)
    {
        "AzureRmQueueStorage"
            {
				$saContext = (Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup -Name $storageAccountName).Context	

                [Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageQueue]$queue = Get-AzureStorageQueue -Name $queueName -Context $saContext -ErrorAction SilentlyContinue

				if ($queue -eq $null)
				{
					[Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageQueue]$queue = New-AzureStorageQueue -Name $queueName -Context $saContext
				}

                $nullQueueErrorMessage = "Queue $queueName could not be retrieved/created from Storage Account $storageAccountName on resource group $resourceGroupName"
            }
        "AzureQueueStorage"
            {
				$saContext = (Get-AzureStorageAccount -StorageAccountName $storageAccountName).Context

                [Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageQueue]$queue = Get-AzureStorageQueue -Name $queueName -Context $saContext -ErrorAction SilentlyContinue

				if ($table -eq $null)
				{
					[Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageQueue]$queue = New-AzureStorageQueue -Name $queueName -Context $saContext
				}

                $nullQueueErrorMessage = "Queue $queueName could not be retrieved/created from Storage Account $storageAccountName on resource group $resourceGroupName"

            }
    }

    # Checking if there a queue got returned
    if ($queue -eq $null)
    {
        throw $nullQueueErrorMessage
    }

    # Returns the queue object
    return [Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageQueue]$queue
}

function Invoke-AzureRmStorageQueuePeekMessage
{
	<#
	.SYNOPSIS
		Gets a single message from the queue without removing it from the queue.
	.DESCRIPTION
		Gets a single message from the queue without removing it from the queue.
    .PARAMETER queue
        Name of the queue to retrieve (using peek) the message
	.EXAMPLE
		# Getting a message without removing or hidding from the other processes using the queue 
		$message =  Invoke-AzureRmStorageQueuePeekMessage -queue $queue
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
        [Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageQueue]$queue
	)

	[Microsoft.WindowsAzure.Storage.Queue.CloudQueueMessage]$message = $queue.CloudQueue.PeekMessage()

	if ($message -ne $null)
	{
		return $message
	}

    return $null
}

function Invoke-AzureRmStorageQueuePeekMessageList
{
	<#
	.SYNOPSIS
		Gets a list of messages from the queue without removing it from the queue.
	.DESCRIPTION
		Getsa  list of messages from the queue without removing it from the queue.
    .PARAMETER queue
        Name of the queue to retrieve (using peek) the message
	.EXAMPLE
		# Getting a message without removing or hidding from the other processes using the queue 
		$messages =  Invoke-AzureRmStorageQueuePeekMessageList -queue $queue 
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
        [Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageQueue]$queue
	)

	# Refreshing approximateMessageCount
	$queue.CloudQueue.FetchAttributes()

	[int]$messageCount = $queue.CloudQueue.ApproximateMessageCount

	if ($messageCount -gt 0)
	{
		return ,$queue.CloudQueue.PeekMessages($messageCount)
	}

    # Returns the queue object
    return $null
}

function Add-AzureRmStorageQueueMessage
{
	<#
	.SYNOPSIS
		Adds a message into the queue.
	.DESCRIPTION
		Adds a message into the queue.
    .PARAMETER queue
        Name of the queue to add the message.
	.EXAMPLE
		Add-AzureRmStorageQueueMessage -queue $queue -message @{"type"="copy";"vhdname"="newvhd.vhd";"sourceStorageAccount"="pmcstorage05";"subscription"="pmcglobal"}
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
        [Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageQueue]$queue,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[Hashtable]$message
	)

	$messageToQueue = New-Object -TypeName Microsoft.WindowsAzure.Storage.Queue.CloudQueueMessage($message | ConvertTo-Json -Depth 100)

	$queue.CloudQueue.AddMessage($messageToQueue)
}

function Clear-AzureRmStorageQueue
{
	<#
	.SYNOPSIS
		Clears all messages in a queue.
	.DESCRIPTION
		Clears all messages in a queue.
    .PARAMETER queue
        Name of the queue to be cleared.
	.EXAMPLE
		Clear-AzureRmStorageQueue -queue $queue
	#>
	[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
	param
	(
		[Parameter(Mandatory=$true)]
        [Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageQueue]$queue
	)

	If ($Pscmdlet.ShouldProcess($queue.Name,"Clear queue"))
	{
        $queue.CloudQueue.Clear()
    }
	
}

function Invoke-AzureRmStorageQueueGetMessage
{
	<#
	.SYNOPSIS
		Get a message from queue and marks it as invisible in the queue for a period of time.
	.DESCRIPTION
		Get a message from queue and marks it as invisible in the queue for a period of time.
    .PARAMETER queue
        Name of the queue to retrieve the message.
	.EXAMPLE
		Clear-AzureRmStorageQueue -queue $queue
	#>
	param
	(
		[Parameter(Mandatory=$true)]
        [Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageQueue]$queue,

		[AllowNull()]
		[System.Timespan]$visibilityTimeout = (New-TimeSpan $(get-date) $(get-date).AddDays(1))
	)

	[Microsoft.WindowsAzure.Storage.Queue.CloudQueueMessage]$message = $queue.CloudQueue.GetMessage($visibilityTimeout)

	if ($message -ne $null)
	{
		return $message
	}

    return $null
	
}

function Remove-AzureRmStorageQueueMessage
{
	<#
	.SYNOPSIS
		Deletes a message from the queue.
	.DESCRIPTION
		Deletes a message from the queue.
    .PARAMETER queue
        Name of the queue to delete the message.
	.PARAMETER message
		CloudQueueMessage message to delete.
	.PARAMETER messageId
		Message ID of the message to delete.
	.PARAMETER popReceipt
		popReceipt value of the message to delete.
	.EXAMPLE
		# removing by using CloudQueueMessage object
		Remove-AzureRmStorageQueueMessage -queue $queue -message $message

		# removing by using CloudQueueMessage object
		Remove-AzureRmStorageQueueMessage -queue $queue -messageId $message.Id -popReceipt $message.popReceipt 
		
	#>
	param
	(
		[Parameter(Mandatory=$true)]
        [Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageQueue]$queue,

		[Parameter(ParameterSetName="BasedOnCloudQueueMessage",Mandatory=$true)]
		[ValidateNotNull()]
		[Microsoft.WindowsAzure.Storage.Queue.CloudQueueMessage]$message,

		[Parameter(ParameterSetName="BasedOnMessageID",Mandatory=$true)]
		[ValidateNotNull()]
		[string]$messageId,

		[Parameter(ParameterSetName="BasedOnMessageID",Mandatory=$true)]
		[ValidateNotNull()]
		[string]$popReceipt
	)
    
	switch ($PSCmdlet.ParameterSetName)
    {
        "BasedOnCloudQueueMessage"
		{
			$queue.CloudQueue.DeleteMessage($message)
		}

		"BasedOnMessageID"
		{
			$queue.CloudQueue.DeleteMessage($messageId,$popReceipt)
		}
	}
}

function Update-AzureRmStorageQueueMessage
{
	<#
	.SYNOPSIS
		Deletes a message from the queue.
	.DESCRIPTION
		Deletes a message from the queue.
    .PARAMETER queue
        Name of the queue to delete the message.
	.PARAMETER message
		CloudQueueMessage message to delete.
	.PARAMETER messageId
		Message ID of the message to delete.
	.PARAMETER popReceipt
		popReceipt value of the message to delete.
	.EXAMPLE

	#>
	param
	(
		[Parameter(Mandatory=$true)]
        [Microsoft.WindowsAzure.Commands.Common.Storage.ResourceModel.AzureStorageQueue]$queue,

		[Parameter(ParameterSetName="BasedOnCloudQueueMessage",Mandatory=$true)]
		[ValidateNotNull()]
		[Microsoft.WindowsAzure.Storage.Queue.CloudQueueMessage]$message,

		[Parameter(ParameterSetName="BasedOnMessageID",Mandatory=$true)]
		[ValidateNotNull()]
		[string]$messageId,

		[Parameter(ParameterSetName="BasedOnMessageID",Mandatory=$true)]
		[ValidateNotNull()]
		[string]$popReceipt
	)
    
	switch ($PSCmdlet.ParameterSetName)
    {
        "BasedOnCloudQueueMessage"
		{
			$queue.CloudQueue.DeleteMessage($message)
		}

		"BasedOnMessageID"
		{
			$queue.CloudQueue.DeleteMessage($messageId,$popReceipt)
		}
	}
}
