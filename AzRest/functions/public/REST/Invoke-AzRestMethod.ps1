function Invoke-AzRestRestMethod {
    [CmdletBinding(SupportsShouldProcess=$True)] #adds Confirm and WhatIf options as parameter options and so forth 
    param(
        [parameter(Mandatory=$true)]
        [PSObject]$token
        ,
        [ValidateSet('Get','Post')]
        [string]$Method = 'Get'
        ,
        [System.Uri]$URI
        ,
        [switch]$Raw
    )

    $params = @{
        ContentType = 'application/x-www-form-urlencoded'
        Headers = @{
            'Authorization' = "Bearer $($token.AccessToken)"
        }
        Method = $Method
        URI = $URI
    }

    If ($raw){
        Invoke-RestMethod @params -TimeoutSec 60 -Verbose:$false
    }Else{
        (Invoke-RestMethod @params -TimeoutSec 60 -Verbose:$false).Value 
    }
}