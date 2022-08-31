function Invoke-AzRestMethod {
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

    [System.Collections.ArrayList]$List = @()

    If ($raw){
        #Invoke-RestMethod @params -TimeoutSec 60 -Verbose:$false
         do {
            $result = Invoke-RestMethod @params -TimeoutSec 60
            $List.AddRange($result)
            $Params.URI = $result.nextLink
        } until ($Params.URI -eq $null)
        return $list
    }
    Else{
        # (Invoke-RestMethod @params -TimeoutSec 60 -Verbose:$false).Value 
        
        do {
            $result = Invoke-RestMethod @params -TimeoutSec 60
            $List.AddRange($result.value)
            $Params.URI = $result.nextLink
        } until ($Params.URI -eq $null)
        return $list
    }
}