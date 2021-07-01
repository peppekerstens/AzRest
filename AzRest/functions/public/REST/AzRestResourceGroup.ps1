function Get-AzRestResourceGroup {
    <#
    .SYNOPSIS
    Gets ResourceGroup Azure resource information.
    
    .DESCRIPTION
    REST based function which gets ResourceGroup information from Azure. Output is a hashtable based PS object but contains similar information as Get-AzResourceGroup.
    Needs a valid access token. This can either (1) be auto generated based on current PS Azure context/session or (2) be created, based on credentials

    .LINK
    https://docs.microsoft.com/en-us/rest/api/resources/resourcegroups
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

    [string]$ResourceGroupNameRestApiPath = 'resourcegroups'
    If ($ResourceGroupName){
        $ResourceGroupNameRestApiPath = "resourceGroups/$($ResourceGroupName)/"
    }

    If ($null -eq $SubscriptionId){
        $SubscriptionId = (Get-AzRestSubscription -token $token).SubscriptionId
    }

    foreach ($sid in $SubscriptionId){
    #should be of type [Microsoft.Azure.Commands.Profile.Models.PSResourceGroup]
        Invoke-AzRestMethod -Uri "https://management.azure.com/subscriptions/$($sid)/$($ResourceGroupNameRestApiPath)?api-version=2019-10-01" @splatToken
    }
}