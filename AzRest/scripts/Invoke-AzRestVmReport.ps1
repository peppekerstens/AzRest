
#$ApiUri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.RecoveryServices/vaults?api-version=2016-06-01"
#$ApiUri = "https://management.azure.com/subscriptions/46ea0f9a-2367-4297-85fe-2924087cf820/resourceGroups/cs-abv-p-rsv-rg/providers/Microsoft.RecoveryServices/vaults/cs-abv-p-rstenant-rsv/backupJobs?api-version=2019-05-13"
#$ApiUri = "https://management.azure.com/subscriptions/46ea0f9a-2367-4297-85fe-2924087cf820/resourceGroups/cs-abv-p-rsv-rg/providers/Microsoft.RecoveryServices/vaults/cs-abv-p-rstenant-rsv/backupJobs/283ab955-3a6a-4b18-8812-62c1516ed2a1?api-version=2019-05-13"
#$ApiUri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Compute/virtualMachines?api-version=2019-03-01"
#$ApiUri = "https://management.azure.com/subscriptions/$subscriptionId/resourceGroups/CS-ABV-P-SQL2-RG/providers/Microsoft.Compute/virtualMachines/abv-sql2?api-version=2019-03-01"
#$ApiUri = "https://management.azure.com/subscriptions/46ea0f9a-2367-4297-85fe-2924087cf820/resourceGroups/CS-ABV-P-SQL2-RG/providers/Microsoft.Compute/virtualMachines/abv-sql2/instanceView?api-version=2019-03-01"
#$ApiUri = "https://management.azure.com/subscriptions/dae07ea3-826a-476a-99cf-6308418bc537/resourceGroups/CS-JBA-P-APP2-RG/providers/Microsoft.Compute/virtualMachines/app2/runCommand?api-version=2019-03-01"

#$result = Invoke-RestMethod -Method Get -Uri $ApiUri -Headers $Headers 
#$result = Invoke-RestMethod -Method Post -Uri $ApiUri -Headers $Headers -Body $body2 -ContentType "text/json" 

#Write-Output $result.value

function Get-AzVmInfo {
    [CmdletBinding()]
    param(
        [Parameter( Mandatory = $true)]
        [Microsoft.Azure.Commands.Compute.Models.PSVirtualMachine]$virtualmachine

    )

    #$RequestAccessTokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
    #$body = "grant_type=client_credentials&client_id=$ClientId&client_secret=$ClientSecret&resource=$Resource"
    #$Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $body -ContentType 'application/x-www-form-urlencoded'

    $timeOut = [timespan]::FromMinutes(10)
    $token = Get-AzRestToken -Token $token -timeOut $timeOut

    $Headers = @{}
    #$Headers.Add("Authorization","$($Token.token_type) "+ " " + "$($Token.access_token)")
    $Headers.Add("Authorization","Bearer $($Token.AccessToken)")

    $SubscriptionId = $currentAzureContext.Subscription

    #$ApiUri = "https://management.azure.com/subscriptions/$($SubscriptionId)/resourceGroups/$($virtualmachine.ResourceGroupName)/providers/Microsoft.Compute/virtualMachines/$($virtualmachine.Name)/instanceView?api-version=2019-03-01"
    
    $ApiUri = "https://management.azure.com/subscriptions/$($SubscriptionId)/providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines?api-version=2017-03-01-preview"
    
    $VmInstanceView = Invoke-RestMethod -Method Get -Uri $ApiUri -Headers $Headers 

    $networkinterfaces =  $virtualmachine.networkprofile.networkinterfaces
    $nif = @()
    foreach ($n in $networkinterfaces){
        $nic = Get-AzNetworkInterface -Name (split-path -path $n.id -leaf) -ResourceGroupName $virtualmachine.ResourceGroupName
        If ($true-eq $nic.IpConfigurations.PublicIpAddress) {
            $pip = Get-AzPublicIpAddress -Name (split-path $nic.IpConfigurations.PublicIpAddress.id -leaf)
        }
        Else {
            $pip = [PSCustomObject]@{
                IpAddress = $null
                PublicIpAllocationMethod = $null
            }
        }
        $nif += @{
            PrimaryInterface = $n.Primary
            PrivateIpAddress = $nic.IpConfigurations.PrivateIpAddress
            AcceleratedNetworking = $nic.EnableAcceleratedNetworking
            PublicIpAddress = $pip.IpAddress
            PublicIpAllocationMethod = $pip.PublicIpAllocationMethod
        }
    }

    $disks = @()
    $od = Get-AzDisk -ResourceGroupName $virtualmachine.ResourceGroupName -DiskName $virtualmachine.storageprofile.osdisk.Name
    $disks += @{
        Type = 'OsDisk'
        Name = $od.Name
        Lun = $null
        DiskSizeGB =$od.DiskSizeGB
        DiskIOPSReadWrite = $od.DiskIOPSReadWrite
        DiskMBpsReadWrite = $od.DiskMBpsReadWrite
        Caching = $virtualmachine.storageprofile.osdisk.Caching
    }

    $datadisks = $virtualmachine.StorageProfile.datadisks
    foreach ($d in $datadisks){
        $dd = Get-AzDisk -ResourceGroupName $virtualmachine.ResourceGroupName -DiskName $d.Name
        $disks += @{
            Type = 'DataDisk'
            Name = $dd.Name
            Lun = $d.Lun
            DiskSizeGB =$dd.DiskSizeGB
            DiskIOPSReadWrite = $dd.DiskIOPSReadWrite
            DiskMBpsReadWrite = $dd.DiskMBpsReadWrite
            Caching = $d.Caching        
        }
    }

    $AzVMInfo = @{
        ResourceGroupName = $virtualmachine.ResourceGroupName
        Name = $virtualmachine.Name
        osType = $virtualmachine.StorageProfile.OsDisk.OSType
        osName = $null
        osVersion = $null
        Location = $virtualmachine.Location
        LicenseType = $virtualmachine.LicenseType
        VmSize = $virtualmachine.hardwareprofile.vmsize
        HyperVGeneration = $VmInstanceView.HyperVGeneration
        nic = $nif
        disk = $disks
    }
    $PreviousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    If ($VmInstanceView.osName){$AzVMInfo.osName = $VmInstanceView.osName}
    If ($VmInstanceView.osVersion){$AzVMInfo.osVersion = $VmInstanceView.osVersion}   
    $ErrorActionPreference = $PreviousErrorActionPreference
    #If ($true -eq $VmInstanceView.osVersion){$AzVMInfo.osVersion = $VmInstanceView.osVersion}else{$AzVMInfo.osVersion=$null}
    [PsCustomObject]$AzVMInfo
}

function Export-AzVMInfo {
    param(
        $Subscription
        ,
        $Path
    )

    If ($Subscription){Get-AzSubscription | Where-Object {$_.Name -like "*$($Subscription)*"}|Select-AzSubscription}
    $vms = Get-AzVm
    
    $result = @()
    $vms | %{$result += Get-AzVmInfo -virtualmachine $_}

    $maxdisks = 0
    $report = @()
    foreach ($r in $result){
        $config = @{
            Name = $r.Name
            osName = $r.osName
            osVersion = $r.osVersion
            VmSize = $r.VmSize
            IpAddress = $r.nic.PrivateIpAddress
        }

        $counter = 1
        foreach ($d in $r.disk){
            $config."Disk$($Counter)" = $d.DiskSizeGB
            $counter += 1
            If ($counter -gt $maxdisks){$maxdisks = $counter}
        }
        $report += [PSCustomObject]$config
    }

    If ($Path){$report|select Name, VmSize, OsName, OsVersion, IpAddress, Disk1, Disk2, Disk3, Disk4, Disk5 |export-csv -Path $Path -Force}
    else{$report}
}
