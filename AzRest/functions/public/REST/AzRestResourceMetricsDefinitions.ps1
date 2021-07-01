function Get-AzRestResourceMetricsDefinitions {
    <#
    .SYNOPSIS
    Gets metric definition information for a certain Azure resource.
    
    .DESCRIPTION
    REST based function which gets metric definition information for a certain Azure resource. Output is a hashtable based PS object.
    Needs a valid access token. This can either (1) be auto generated based on current PS Azure context/session or (2) be created, based on credentials

    .LINK
    #https://docs.microsoft.com/en-us/azure/azure-monitor/platform/rest-api-walkthrough
    #>
    param(
        [string]$ResourceUri
        ,
        [PSObject]$token
    )

    $splatToken = @{}
    If ($token){
        $splatToken.token = $token 
    }Else{
        $splatToken.token = Get-AzRestToken
    }

    Invoke-AzRestMethod -Uri "https://management.azure.com$($ResourceUri)/providers/microsoft.insights/metricDefinitions?api-version=2018-01-01" @splatToken
}