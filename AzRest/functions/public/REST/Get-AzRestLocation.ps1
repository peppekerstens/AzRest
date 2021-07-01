function Get-AzRestLocation {
    <#
    .SYNOPSIS
    Gets all available geo-locations.
    
    .DESCRIPTION
    REST based function which gets all available geo-locationfrom Azure for a ceratin resource provider. Output is a hashtable based PS object.
    Needs a valid access token. This can either (1) be auto generated based on current PS Azure context/session or (2) be created, based on credentials

    .LINK
    https://docs.microsoft.com/en-us/rest/api/resources/Subscriptions/ListLocations

    #> 
    param(
        [parameter(Mandatory=$true)]
        [string]$SubscriptionId
        ,
        [PSObject]$token        
    )

    $splatToken = @{}
    If ($token){
        $splatToken.token = $token 
    }Else{
        $splatToken.token = Get-AzRestToken
    }

    Invoke-AzRestMethod -Uri "https://management.azure.com/subscriptions/$($SubscriptionId)/locations?api-version=2019-11-01" @splatToken
}