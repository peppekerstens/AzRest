function Convert-AzRestVmReportToFlat {
    param(
        [PSObject[]]$AzVmReport
    )

    $maxdisks = 0
    $AzVmReport | %{if ($_.disk.count -gt $maxdisks){$maxdisks = $_.disk.count}}

    $extensionCount = 0
    $AzVmReport | %{if ($_.otherExtensions.count -gt $extensionCount){$extensionCount = $_.otherExtensions.count}}

    $report = @()
    foreach ($r in $AzVmReport){
        $AzVMInfo = [ordered]@{
            SubscriptionName = $r.Subscription.displayName
            ResourceGroupName =  $r.ResourceGroupName
            VmName = $r.Name
            osType = $r.osType
            osName = $r.osName
            osVersion = $r.osVersion
            Location = $r.Location
            VmSize = $r.VmSize
            HyperVGeneration = $r.HyperVGeneration
            IpAddress = $r.nic.PrivateIpAddress
            PublicIPAddress = $r.nic.PublicIpAddress
            AcceleratedNetworking = $r.nic.AcceleratedNetworking
            sqlImageOffer = $r.sql.sqlImageOffer
            sqlServerLicenseType = $r.sql.sqlServerLicenseType
            sqlImageSku = $r.sql.sqlImageSku
            bootDiagnostics = $r.bootDiagnostics
            extensionIaaSAntimalwareVersion = $r.extensionIaaSAntimalwareVersion
            SqlIaasExtensionVersion = $r.SqlIaasExtensionVersion
            extensionSiteRecoveryVersion = $r.extensionSiteRecoveryVersion
        }
        for ($i = 0; $i -lt $maxdisks; $i++){
            Try {
                $DiskSizeGB = $r.disk[$i].DiskSizeGB
            }
            Catch{
                $DiskSizeGB = $null
            }
            #$AzVMInfo += @{"Disk$($i+1)" = $DiskSizeGB}
            $AzVMInfo.Add("Disk$($i+1)", $DiskSizeGB)
        }
        for ($i = 0; $i -lt $extensionCount; $i++){
            Try {
                $extensionName = $r.otherExtensions[$i].Name
            }
            Catch{
                $extensionName = $null
            }
            #$AzVMInfo += @{"Disk$($i+1)" = $DiskSizeGB}
            $AzVMInfo.Add("OtherExtension$($i+1)", $extensionName)
        }
        $report += [PSCustomObject]$AzVMInfo
    }
    #force ordering
    $report #| Select-Object SubscriptionName,ResourceGroupName,VmName,
}
