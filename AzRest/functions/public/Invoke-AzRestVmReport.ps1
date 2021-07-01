function Invoke-AzRestVmReport {
    [CmdletBinding()]
    param(
        [PSObject]$token
        ,
        [string[]]$SubscriptionId
        ,
        [switch]$metrics
        ,
        [ValidateRange(1,30)]
        [int]$days = 1
    )

    $splatToken = @{}
    If ($token){
        $splatToken.token = $token 
    }Else{
        $splatToken.token = Get-AzRestToken
    }

    $AzSubscription = Get-AzRestSubscription -token $token

    If ($null -eq $SubscriptionId){
        $SubscriptionId = $AzSubscription.SubscriptionId
    }

    foreach ($sid in $SubscriptionId){
        $splatSubscriptionId = @{'SubscriptionId' = $sid}
        $AzVm = Get-AzRestVm @splatToken @splatSubscriptionId -Status
        $SqlVirtualMachines = Get-AzRestSqlVirtualMachines @splatToken @splatSubscriptionId
        $AzDisks = Get-AzRestDisk @splatToken @splatSubscriptionId
        $AzNetworkInterface = Get-AzRestNetworkInterface @splatToken @splatSubscriptionId
        $AzPublicIpAddress = Get-AzRestPublicIpAddress @splatToken @splatSubscriptionId
        foreach ($vm in $AzVm) {
            #network
            $nics = $vm.properties.networkprofile.networkinterfaces
            $nif = @()
            foreach ($n in $nics){
                $nopip = $false
                $nic = $AzNetworkInterface | Where-Object {$_.Id -eq $n.id}
                If (($nic.properties.Ipconfigurations.properties | Get-Member).Name -contains 'publicIPAddress') {
                    $validPip = $AzPublicIpAddress | Where-Object {($_.properties | Get-Member).Name -contains 'ipConfiguration'}
                    $pip = $validPip | Where-Object {$_.properties.ipConfiguration.id -eq $nic.properties.Ipconfigurations.properties.PublicIPAddress.id}
                    If ($null -eq $pip){
                        $nopip = $true
                    }
                }
                Else {
                    $nopip = $true
                }
                if ($nopip){
                    $pip = @{
                        properties = [ordered]@{
                            IpAddress = $null
                            PublicIpAllocationMethod = $null
                        }
                    }
                }
                
                Try{ $PrimaryInterace = $nic.properties.Primary }Catch{ $PrimaryInterace = $false }
                $nif += [PsCustomObject][ordered]@{
                    PrimaryInterface = $PrimaryInterace
                    PrivateIpAddress = $nic.properties.IpConfigurations.properties.PrivateIpAddress
                    AcceleratedNetworking = $nic.properties.EnableAcceleratedNetworking
                    PublicIpAddress = $pip.properties.IpAddress
                    PublicIpAllocationMethod = $pip.properties.PublicIpAllocationMethod
                }
            }
            Write-Verbose "$($vm.Name): Found $($nics.count) networkinterfaces, has public ip: $(-not $nopip)"

            #disks
            $disks = @()
            #werkt alleen als het managed disks zijn!
            If (($vm.properties.StorageProfile.OsDisk | Get-Member).Name -contains 'managedDisk') {
                $od = $AzDisks | Where-Object {$_.Id -eq $vm.properties.StorageProfile.OsDisk.managedDisk.id}
                $disks += [PsCustomObject][ordered]@{
                    Profile = 'OsDisk'
                    Type = 'managed'
                    Name = $od.Name
                    Lun = $null
                    DiskSizeGB =$od.properties.DiskSizeGB
                    DiskIOPSReadWrite = $od.properties.DiskIOPSReadWrite
                    DiskMBpsReadWrite = $od.properties.DiskMBpsReadWrite
                    Caching = $vm.properties.storageprofile.osdisk.Caching
                }
            }Else{
                $disks += [PsCustomObject][ordered]@{
                    Profile = 'OsDisk'
                    Type = 'vhd'
                    Name = $vm.properties.StorageProfile.OsDisk.Name
                    Lun = $null
                    DiskSizeGB = 0
                    DiskIOPSReadWrite = 0
                    DiskMBpsReadWrite = 0
                    Caching = $vm.properties.storageprofile.osdisk.Caching
                }
            }
            $datadisks = $vm.properties.StorageProfile.datadisks
            foreach ($d in $datadisks){
                If (($d | Get-Member).Name -contains 'managedDisk') {
                    $dd = $AzDisks | Where-Object {$_.Id -eq $d.managedDisk.id}
                    $disks += [PsCustomObject][ordered]@{
                        Profile = 'DataDisk'
                        Type = 'managed'
                        Name = $d.Name
                        Lun = $d.Lun
                        DiskSizeGB = $dd.properties.DiskSizeGB
                        DiskIOPSReadWrite = $dd.properties.DiskIOPSReadWrite
                        DiskMBpsReadWrite = $dd.properties.DiskMBpsReadWrite
                        Caching = $d.Caching        
                    }
                }Else{
                    $disks += [PsCustomObject][ordered]@{
                        Profile = 'DataDisk'
                        Type = 'vhd'
                        Name = $d.Name
                        Lun = $null
                        DiskSizeGB = 0
                        DiskIOPSReadWrite = 0
                        DiskMBpsReadWrite = 0
                        Caching = $d.Caching
                    }
                }
            }
            Write-Verbose "$($vm.Name): Found $($datadisks.count) data disks"

            #sql
            $sqlinfo = [ordered]@{
                sqlImageOffer = $null
                sqlServerLicenseType = $null
                sqlImageSku = $null
            }
            $sql = $SqlVirtualMachines | Where-Object {$_.properties.virtualMachineResourceId -eq $vm.Id}
            if ($sql){
                Try {$sqlinfo.sqlImageOffer = $sql.properties.sqlImageOffer}Catch{$sqlinfo.sqlImageOffer = $null}
                Try {$sqlinfo.sqlServerLicenseType= $sql.properties.sqlServerLicenseType}Catch{$sqlinfo.sqlServerLicenseType = $null}
                Try {$sqlinfo.sqlImageSku = $sql.properties.sqlImageSku}Catch{$sqlinfo.sqlImageSku= $null}
            }
            $sqlinfo = [PsCustomObject]$sqlinfo
            Write-Verbose "$($vm.Name): Has SQL installed $($sql -and $true)"

            #subscription
            $SubcrInfo = $AzSubscription | Where-Object {$_.subscriptionId -eq $sid}
            $subscriptionInfo = [PsCustomObject]@{
                displayName = $SubcrInfo.displayName
                subscriptionId = $SubcrInfo.subscriptionId
                subscriptionPolicies = $SubcrInfo.subscriptionPolicies
            }
            
            #extensions - create some order for viewing
            Try{
                $IaaSAntimalwareVersion = $vm.instanceview.extensions.Where{$_.Name -eq 'IaaSAntimalware'}.typeHandlerVersion
            }
            Catch{
                $IaaSAntimalwareVersion = $null
            }
            Try{
                $SiteRecoveryVersion = $vm.instanceview.extensions.Where{$_.Name -like 'SiteRecovery-*'}.typeHandlerVersion
            }
            Catch{
                $SiteRecoveryVersion = $null
            }
            Try{
                $SqlIaasExtensionVersion = $vm.instanceview.extensions.Where{$_.Name -eq 'SqlIaasExtension'}.typeHandlerVersion
            }
            Catch{
                $SqlIaasExtensionVersion = $null
            }
            #remaining extensions
            $extensions = $vm.instanceview.extensions.Where{($_.Name -ne 'IaaSAntimalware') -and ($_.Name -ne 'SqlIaasExtension') -and ($_.Name -notlike 'SiteRecovery-*') }
           
            #agregate
            $AzVMInfo = [ordered]@{
                Subscription = $subscriptionInfo
                ResourceGroupName = $vm.id.split('/')[4]
                Name = $vm.Name
                Status = $vm.instanceview.statuses.where{$_.code -like 'PowerState*'}.displaystatus
                osType = $vm.properties.StorageProfile.OsDisk.OSType
                osName = $null
                osVersion = $null
                Location = $vm.Location
                #LicenseType = $vm.properties.LicenseType
                VmSize = $vm.properties.hardwareprofile.vmsize
                nic = $nif
                disk = $disks
                sql = $sqlinfo
                extensionIaaSAntimalwareVersion = $IaaSAntimalwareVersion
                SqlIaasExtensionVersion = $SqlIaasExtensionVersion
                extensionSiteRecoveryVersion = $SiteRecoveryVersion
                otherExtensions = $extensions
            }
            $PreviousErrorActionPreference = $ErrorActionPreference
            $ErrorActionPreference = 'SilentlyContinue'
            If ($vm.properties.diagnosticsProfile.bootDiagnostics.storageUri){$AzVMInfo.bootDiagnostics = $vm.properties.diagnosticsProfile.bootDiagnostics.storageUri}Else{$AzVMInfo.bootDiagnostics = $null}

            $VmInstanceView = Get-AzRestVmInstanceView -vmAzResourceId $vm.Id
            If ($VmInstanceView.HyperVGeneration){$AzVMInfo.HyperVGeneration = $VmInstanceView.HyperVGeneration} 
            If ($VmInstanceView.osName){$AzVMInfo.osName = $VmInstanceView.osName}
            If ($VmInstanceView.osVersion){$AzVMInfo.osVersion = $VmInstanceView.osVersion}   
            $ErrorActionPreference = $PreviousErrorActionPreference

            #metrics
            If($metrics){
                Write-Verbose "$($vm.Name): Collecting metrics...."
                $AzVMInfo.Metrics = Invoke-AzRestVmMetricsReport -vm $vm -days $days
            }Else{
                $AzVMInfo.Metrics = $null
            }
            #If ($true -eq $VmInstanceView.osVersion){$AzVMInfo.osVersion = $VmInstanceView.osVersion}else{$AzVMInfo.osVersion=$null}
            [PsCustomObject]$AzVMInfo
        }
    }
}