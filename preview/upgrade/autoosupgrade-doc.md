# Azure VM scale set automatic OS upgrades

Automatic OS image upgrade is a new preview feature for Azure VM scale sets which supports automatic upgrade of VM images across a scale set.

Automatic OS upgrade has the following characteristics:
- Once configured, the latest OS image published by image publishers is automatically applied to the scale set without user intervention.
- Upgrades instances in a rolling manner one batch at a time each time a new platform image is published by the publisher.
- Integrates with application health probe (optional but highly recommended for safety).
- Works for all VM sizes.
- Works for Windows and Linux platform images.
- You can opt out of automatic upgrades at any time.
- The OS Disk of a VM is replaced with the new OS Disk created with latest image version. The extensions and custom data scripts are re-initialized, while persisted data disks are retained.


## Preview notes 
- While in preview, automatic OS upgrades only support 3 OS skus (see below), and have no SLA or guarantees. We would love to get your feedback, but it is recommended to not enable them on production critical workloads during preview.
- Support for scale sets in Service Fabric clusters is coming soon.
- Azure autoscale is __not__ currently supported with VM scale set automatic OS upgrade.
- Azure disk encryption (currently in preview) is __not__ currently supported with VM scale set automatic OS upgrade.
- Portal experience coming soon.

## Pre-requisites
Automatic OS upgrades are offered when the following conditions are met:

	The OS image is a platform Image, and in the VMSS model the Version = _latest_.
    
    The following SKUs are currently supported (more will be added):
	
		Publisher: MicrosoftWindowsServer
		Offer: WindowsServer
		Sku: 2012-R2-Datacenter
		Version: latest
		
		Publisher: MicrosoftWindowsServer
		Offer: WindowsServer
		Sku: 2016-Datacenter
		Version: latest

		Publisher: Canonical
		Offer: UbuntuServer
		Sku: 16.04-LTS
		Version: latest


## Application Health
```
# Nathan TBD
```

During an OS Upgrade, VM instances in a VMSS are upgraded one batch at a time. The upgrade should continue only if the customer application is healthy on the upgraded VM instances. Therefore it is recommended that customer application provides rich health signals to the VMSS OS Upgrade engine. By default VMSS OS Upgrades considers VM Powerstate and Extension Provisioning State to determine if a VM instance is healthy post upgrade. During the OS Upgrade of a VM instance, the OS Disk on a VM instance is replaced with a new disk based on latest image version. The extensions are re-initialized on these VMs. Customers can use extensions like custom-script extension, to author custom logic to capture the health of the application, and only return provisioning success if the application is running healthy. Only when all the extensions on a VM have Provision Success state, is the application considered healthy. 

Customer can optionally also specify Application Health Probes for deeper Health signals. Application Health Probes are Load Balancer Probes that a customer can configure to be used as Application health signal. After an OS Upgrade the customer application on a VMSS VM instance can respond Healthy or UnHealthy status similar to the Load Balancer. For more documentation on how Load Balancer Probe work <<follow this link>>. An Application Health Probe is not required for automatic OS upgrades, but it is highly recommended.


### Configuring a Load Balancer Probe as Application Health Probe on a VMSS

As a best practice, a new load-balancer probe should be created explicitly for VMSS health. The same endpoint for an existing HTTP probe or TCP probe may be used, but a health probe may require different behavior than that of a traditional load-balancer probe. For example, a traditional load-balancer probe may return unhealthy if the load on the instance is too high, whereas that may not be appropriate for determining the instance health during an automatic OS upgrade. The probe should also be set up to have a high probing rate.

The load-balancer probe can be referenced in the networkProfile of the VMSS and can be associated with either an internal or public facing load-balancer:
```
"networkProfile": {
  "healthProbe" : {
    "id": "[concat(variables('lbId'), '/probes/', variables('sshProbeName'))]"
  },
  "networkInterfaceConfigurations":
  ...
```
### 

## Enforcing an OS image upgrade policy across your subscription
For safe upgrades it is highly recommended to enforce an upgrade policy, which includes an application health probe, across your subscription. You can do this by applying the following ARM policy to your subscription, which will reject deployments that do not have automated OS image upgrade settings configured:
```
1. Get builtin ARM policy definition: 
$policyDefinition = Get-AzureRmPolicyDefinition -Id "/providers/Microsoft.Authorization/policyDefinitions/465f0161-0087-490a-9ad9-ad6217f4f43a"

2. Assign policy to a subscription: 
New-AzureRmPolicyAssignment -Name "Enforce automatic OS upgrades with app health checks" -Scope "/subscriptions/<SubscriptionId>" -PolicyDefinition $policyDefinition

```

## Getting started
You can register for the automated OS upgrade feature by running these Azure PowerShell commands:

```
Register-AzureRmProviderFeature -ProviderNamespace Microsoft.Compute -FeatureName AutoOSUpgradePreview
# Wait 10 minutes until registration state transitions to 'Registered' (check using Get-AzureRmProviderFeature)
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Compute
```

To use application health probes, register for application health feature by running these Azure PowerShell commands:

```
Register-AzureRmProviderFeature -ProviderNamespace Microsoft.Network -FeatureName AllowVmssHealthProbe
# Wait 10 minutes until registration state transitions to 'Registered' (check using Get-AzureRmProviderFeature)
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Network
```


## How to configure auto-updates

- Ensure automaticOSUpgrade property is set to true in the VMSS model definition. 

## Automatic OS Upgrade Policy

A VM scale set can have instances spread across single or multiple Placement Groups. As described above, VMSS OS Upgrades executes following steps:

1) Identifies the batch of VM instances to upgrade, with a batch having maximum 20% of total instance count
2) If more than 20% of instances are UnHealthy, stop the upgrade, otherwise proceed.
3) Upgrades the next batch of VM instances
4) If more than 20% of upgraded instances are UnHealthy, stop the upgrade, otherwise proceed.
5) If the customer has opted in for Application Health Probes, continue immediately to the next batch otherwise wait 30 min between batches.
6) If there are remaining instances to upgrade, goto 2) for the next batch, else upgrade is complete

VMSS OS Upgrade Engine checks for the overall VM instance health before upgrading every batch. While upgrading a batch, there may be other concurrent Planned or UnPlanned maintenance happening in Azure Datacenters that may impact availbility of your VMs. Hence, it is possible that temporarily more than 20% instances may be down. In such cases, at the end of current batch VMSS will stop the upgrade.

## VMSS Rolling Upgrades

VMSS Automatic OS Upgrades, leverages a Rolling Upgrador Engine underneath, that updates a Batch of VM instances at a time, checks the instance health, and drives the update to completion. It is now possible for the customers to leverage this Rolling Upgrador, to drive their own updates to a VMSS.

- Syntax
```

SEAN TO CHECK and confirm, this property bag for Rolling Upgrades. Also to check where the AutomaticOSUpgrade element is.

"upgradePolicy": {
    "mode": "Rolling", // Must be "Rolling" for manual upgrades; can be anything for automatic OS upgrades
    "automaticOSUpgrade": "true" or "false",
	  "rollingUpgradePolicy": {
		  "maxBatchInstancePercent": 20,
		  "maxUnhealthyInstancePercent": 20,
		  "maxUnhealthyUpgradedInstancePercent": 20,
		  "pauseTimeBetweenBatches": "PT0S"
	  }
}
```
### Property descriptions
__maxBatchInstancePercent__ – 
The maximum percent of total virtual machine instances that will be upgraded simultaneously by the rolling upgrade in one batch. As this is a maximum, unhealthy instances in previous or future batches can cause the percentage of instances in a batch to decrease to ensure higher reliability.
The default value for this parameter is 20.

__pauseTimeBetweenBatches__ – 
The wait time between completing the update for all virtual machines in one batch and starting the next batch. 
The time duration should be specified in ISO 8601 format for duration (https://en.wikipedia.org/wiki/ISO_8601#Durations)
The default value is 0 seconds (PT0S).

__maxUnhealthyInstancePercent__ -         
The maximum percentage of the total virtual machine instances in the scale set that can be simultaneously unhealthy, either as a result of being upgraded, or by being found in an unhealthy state by the virtual machine health checks before the rolling upgrade aborts. This constraint will be checked prior to starting any batch.
The default value for this parameter is 20.

__maxUnhealthyUpgradedInstancePercent__ – 
The maximum percentage of upgraded virtual machine instances that can be found to be in an unhealthy state. This check will happen after each batch is upgraded. If this percentage is ever exceeded, the rolling update aborts.
The default value for this parameter is 20.

## Adding a load-balancer probe for determining health of the rolling upgrade
Before the VMSS can be created or moved into rolling upgrade mode, a load-balancer probe used to determine VM instance health must be added.


## Example templates

### Automatic rolling upgrades - Ubuntu 16.04-LTS

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fvm-scale-sets%2Fmaster%2Fpreview%2Fupgrade%2Fautoupdate.json" target="_blank">
    <img src="http://azuredeploy.net/deploybutton.png"/>
</a>

## Checking automatic rolling upgrade status

GET on `/subscriptions/subscription_id/resourceGroups/resource_group/providers/Microsoft.Compute/virtualMachineScaleSets/vmss_name/rollingUpgrades/latest?api-version=2017-03-30`

```
{
  "properties": {
    "policy": {
      "maxBatchInstancePercent": 20,
      "maxUnhealthyInstancePercent": 5,
      "maxUnhealthyUpgradedInstancePercent": 5,
      "pauseTimeBetweenBatches": "PT0S"
    },
    "runningStatus": {
      "code": "Completed",
      "startTime": "2017-06-16T03:40:14.0924763+00:00",
      "lastAction": "Start",
      "lastActionTime": "2017-06-22T08:45:43.1838042+00:00"
    },
    "progress": {
      "successfulInstanceCount": 3,
      "failedInstanceCount": 0,
      "inprogressInstanceCount": 0,
      "pendingInstanceCount": 0
    }
  },
  "type": "Microsoft.Compute/virtualMachineScaleSets/rollingUpgrades",
  "location": "southcentralus"
}
```