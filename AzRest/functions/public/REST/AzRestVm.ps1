function Get-AzRestVm {
    <#
    .SYNOPSIS
    Gets Virtual Machine Azure resource information.
    
    .DESCRIPTION
    REST based function which gets Virtual Machine information from Azure. Output is a hashtable based PS object but contains similar information as Get-AzDisk.
    Needs a valid access token. This can either (1) be auto generated based on current PS Azure context/session or (2) be created, based on credentials
    #> 
    param(
        [string]$ResourceGroupName
        ,
        [string]$Location
        ,
        [PSObject]$token
        ,
        [string[]]$SubscriptionId
        ,
        [switch]$Status
    )

    $splatToken = @{}
    If ($token){
        $splatToken.token = $token 
    }Else{
        $splatToken.token = Get-AzRestToken
    }

    [string]$ResourceGroupNameRestApiPath = [string]::Empty
    If ($ResourceGroupName){
        $ResourceGroupNameRestApiPath = "resourceGroups/$($ResourceGroupName)/"
    }

    [string]$LocationRestApiPath = [string]::Empty
    If ($location){
        $locationRestApiPath = "locations/$($location)/"
    }

    If ($null -eq $SubscriptionId){
        $SubscriptionId = (Get-AzRestSubscription -token $token).SubscriptionId
    }

    #should be of type 
    foreach ($sid in $SubscriptionId){
        $vms = Invoke-AzRestMethod -Uri "https://management.azure.com/subscriptions/$($sid)/$($ResourceGroupNameRestApiPath)providers/Microsoft.Compute/$($locationRestApiPath)virtualMachines?api-version=2019-03-01" @splatToken
        If ($PSBoundParameters.ContainsKey('Status')){
            
            foreach ($vm in $vms){
                $InstanceView = Get-AzRestvmInstanceview -vmAzResourceId $vm.Id @splatToken
                $vmhash = @{}
                $vm.psobject.properties | Foreach-Object { $vmhash[$_.Name] = $_.Value }
                $vmhash.InstanceView = $InstanceView
                [PSCustomObject]$vmhash
            }
            #return $result
        }Else{
            $vms
        }
    }
}

function Start-AzRestVm {
    #source: https://docs.microsoft.com/en-us/rest/api/compute/virtualmachines/start
    [CmdletBinding(SupportsShouldProcess=$True)] #adds Confirm and WhatIf options as parameter options and so forth 
    param(
        [parameter(Mandatory=$true)]
        [string]$vmAzResourceId
        ,
        [PSObject]$token
    )

    $splatToken = @{}
    If ($token){
        $splatToken.token = $token 
    }Else{
        $splatToken.token = Get-AzRestToken
    }

    If ($WhatIfPreference -eq $true){
        Write-host "What If: Start $($vmAzResourceId)" -ForegroundColor Cyan
    }Else{
        Invoke-AzRestMethod -Method 'Post' -Uri "https://management.azure.com/$($vmAzResourceId)/start?api-version=2019-07-01" @splatToken
    }
}

function Stop-AzRestVm {
    #source: https://docs.microsoft.com/en-us/rest/api/compute/virtualmachines/poweroff
    #https://docs.microsoft.com/en-us/rest/api/compute/virtualmachines/deallocate
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='High')] #adds Confirm and WhatIf options as parameter options and so forth 
    param(
        [parameter(Mandatory=$true)]
        [string]$vmAzResourceId
        ,
        [PSObject]$token
        ,
        [switch]$poweroff
        ,
        [switch]$Force
    )

    Begin{
        $splatToken = @{}
        If ($token){
            $splatToken.token = $token 
        }Else{
            $splatToken.token = Get-AzRestToken
        }

        $offMethod = 'deallocate'
        If ($poweroff){
            $offMethod = 'powerOff'
        }
    }

    Process {
        if ($Force -or $PSCmdlet.ShouldProcess($vmAzResourceId)) {
            Invoke-AzRestMethod -Method 'Post' -Uri "https://management.azure.com/$($vmAzResourceId)/$($offMethod)?api-version=2019-07-01" @splatToken
        }
    }
}