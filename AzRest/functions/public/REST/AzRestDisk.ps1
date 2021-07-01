function Get-AzRestDisk {
    <#
    .SYNOPSIS
    Gets disk information Azure resource information
    
    .DESCRIPTION
    REST based function which gets disk information from Azure. Output is a hashtable based PS object but contains similar information as Get-AzDisk.
    Needs a valid access token. This can either (1) be auto generated based on current PS Azure context/session or (2) be created, based on credentials
    #>
    param(
        [string]$ResourceGroupName
        ,
        [PSObject]$token
        ,
        [string[]]$SubscriptionId
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

    If ($null -eq $SubscriptionId){
        $SubscriptionId = (Get-AzRestSubscription -token $token).SubscriptionId
    }

    foreach ($sid in $SubscriptionId){
        Invoke-AzRestMethod -Uri "https://management.azure.com/subscriptions/$($sid)/$($ResourceGroupNameRestApiPath)providers/Microsoft.Compute/disks?api-version=2019-07-01" @splatToken 
    }
}