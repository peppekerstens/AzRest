function Get-AzRestToken {
    <#
    source:
    https://keithbabinec.com/2018/10/11/how-to-call-the-azure-rest-api-from-powershell/
    https://docs.microsoft.com/en-us/azure/governance/blueprints/create-blueprint-rest-api
    https://docs.microsoft.com/en-us/archive/blogs/igorpag/using-powershell-as-an-azure-arm-rest-api-client
    https://docs.microsoft.com/en-us/archive/blogs/stefan_stranger/using-the-azure-arm-rest-api
    https://docs.microsoft.com/en-us/azure/azure-monitor/platform/rest-api-walkthrough
    https://www.cryingcloud.com/blog/2018/10/16/capturing-and-using-api-queries-from-azure-in-powershell-with-fiddler

    WARNING: this command may fail under PS5.X with following error (or alike):
    Exception calling "AcquireAccessToken" with "1" argument(s): "multiple_matching_tokens_detected: The cache contains multiple tokens satisfying the requirements. Call AcquireToken again providing more arguments (e.g. UserId)"
    cause 'seems' to be calling older ID.tech (ADAL), while MS moved to MSAL
    source (amongst):https://github.com/MicrosoftDocs/azure-docs/issues/36887
    solution is:
    logoff current azure session    
    run: Clear-AzContext
    login to azure again

    the issue is not present running PS 6 and above

    detailed info in how to create an token: https://blogs.technet.microsoft.com/paulomarques/2016/04/05/working-with-azure-rest-apis-from-powershell-getting-page-and-block-blob-information-from-arm-based-storage-account-sample-script/
    
    needs at least the az.accounts module of the az module collection
    #>
    [CmdletBinding(DefaultParametersetName='Default')]
    Param (
        [parameter(Mandatory=$true, ParameterSetName="Rest")]
        [string]$TenantId
        ,
        [parameter(Mandatory=$true, ParameterSetName="Rest")]
        [string]$ClientId
        ,
        [parameter(Mandatory=$true, ParameterSetName="Rest")]
        [string]$ClientSecret
        #[parameter(Mandatory=$true, ParameterSetName="Token")]
        #[PSObject]$token
        #,
        #[parameter(Mandatory=$true, ParameterSetName="Token")]
        #[timespan]$timeOut
    )

    #$timeOut = [timespan]::FromMinutes(10)
    
    #$CreateNewToken = $false
    #If ($PsCmdlet.ParameterSetName -eq 'Token'){
    #    $now = (Get-Date).ToUniversalTime()
    #    If ((($token.ExpiresOn).Ticks - $now.Ticks) -lt $Timeout.Ticks){
    #        $CreateNewToken = $true
    #    }
    #}
    #Else{
    #    $CreateNewToken = $true
    #}

    If ($TenantId){
        $Resource = "https://management.core.windows.net/"
        $RequestAccessTokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
        $body = "grant_type=client_credentials&client_id=$ClientId&client_secret=$ClientSecret&resource=$Resource"
        $Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $body -ContentType 'application/x-www-form-urlencoded'
    }
    Else{
        $currentAzureContext = Get-AzContext
        $azureRmProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
        $profileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($azureRmProfile)
        $Token = $profileClient.AcquireAccessToken($currentAzureContext.Subscription.TenantId)
    }

    $Return = @{}
    If ($Token.AccessToken){
        $Return.token_type = $Token.LoginType
        $Return.expires_in = 3600
        $Return.ext_expires_in = 3600
        $Return.expires_on = ''
        $Return.not_before = ''
        $Return.access_token = $Token.AccessToken
        $Return.AccessToken = $Token.AccessToken
        $Return.LoginType = $Token.LoginType
        $Return.UserId = $Token.UserId
        $Return.TenantId = $Token.TenantId
    }
    If ($Token.access_token){
        $Return.token_type = $Token.token_type
        $Return.expires_in = $Token.expires_in
        $Return.ext_expires_in = $Token.ext_expires_in
        $Return.expires_on = $Token.expires_on
        $Return.not_before = $Token.not_before
        $Return.access_token = $Token.access_token
        $Return.AccessToken = $Token.access_token
        $Return.LoginType = $Token.token_type
        $Return.UserId = $ClientId
        $Return.TenantId = $TenantId
    }
    return [PSCustomObject]$Return
}
