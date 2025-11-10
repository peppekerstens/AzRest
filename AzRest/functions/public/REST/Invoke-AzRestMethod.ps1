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
        ,
        [int]$TimeoutSec = 10
    )

    $params = @{
        ContentType = 'application/x-www-form-urlencoded'
        Headers = @{
            'Authorization' = "Bearer $($token.AccessToken)"
        }
        Method = $Method
        URI = $URI
        TimeoutSec = $TimeoutSec
    }

    [System.Collections.ArrayList]$List = @()

    If ($raw){
        Invoke-RestMethod @params
        
    }
    Else{
        # (Invoke-RestMethod @params -TimeoutSec 60 -Verbose:$false).Value 
        
        do {
            $result = Invoke-RestMethod @params
            if ($null -ne $result){
                $List.AddRange($result.value)
                $Params.URI = $result.nextLink
            }
            else {
                $Params.URI = $null
            }
        } until ($Params.URI -eq $null)
        return $list
    }
}