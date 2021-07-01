function Get-AzRestSqlVirtualMachines {
    <#
    .SYNOPSIS
    Gets SqlVirtualMachine Azure resource information.
    
    .DESCRIPTION
    REST based function which gets SqlVirtualMachine information from Azure. Output is a hashtable based PS object.
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
        Invoke-AzRestMethod -Uri "https://management.azure.com/subscriptions/$($sid)/$($ResourceGroupNameRestApiPath)providers/Microsoft.SqlVirtualMachine/sqlVirtualMachines?api-version=2017-03-01-preview" @splatToken
    }
}