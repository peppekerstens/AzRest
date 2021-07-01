function Get-AzRestSubscription {
    <#
    .SYNOPSIS
    Gets Subscription Azure resource information.
    
    .DESCRIPTION
    REST based function which gets Subscription information from Azure. Output is a hashtable based PS object.
    Needs a valid access token. This can either (1) be auto generated based on current PS Azure context/session or (2) be created, based on credentials
    #>   
    param(
        [PSObject]$token
    )

    $splatToken = @{}
    If ($token){
        $splatToken.token = $token 
    }Else{
        $splatToken.token = Get-AzRestToken
    }

    #should be of type [Microsoft.Azure.Commands.Profile.Models.PSAzureSubscription]
    Invoke-AzRestMethod -Uri "https://management.azure.com/subscriptions?api-version=2019-11-01" @splatToken
}