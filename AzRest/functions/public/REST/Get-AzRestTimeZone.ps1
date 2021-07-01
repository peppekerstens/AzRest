function Get-AzRestTimeZone {
    [CmdletBinding(DefaultParameterSetName = 'Id')]
    <#
    .SYNOPSIS
    Gets all available geo-locations.
    
    .DESCRIPTION
    REST based function which gets all available geo-locationfrom Azure for a ceratin resource provider. Output is a hashtable based PS object.
    Needs a valid access token. This can either (1) be auto generated based on current PS Azure context/session or (2) be created, based on credentials

    .LINK
    https://docs.microsoft.com/en-us/rest/api/maps/timezone

    #> 
    param(
        [Parameter(Mandatory = $true,
        ParameterSetName = 'Id',
        HelpMessage = 'Provide IANA tz database name')]
        [string]$Name
        ,
        [Parameter(Mandatory = $true,
        ParameterSetName = 'Coordinates')]
        [double]$latitude
        ,
        [Parameter(Mandatory = $true,
        ParameterSetName = 'Coordinates')]
        [double]$longitude
        ,
        [Parameter(Mandatory = $true)]
        [string]$ApiKey
    )

    Switch ($PSCmdlet.ParameterSetName) {
        'Id'            {$type = 'byId'; $query = "query=$($Name)"}
        'Coordinates'   {$type = 'byCoordinates'; $query = "query=$($latitude),$($longitude)"}
    }

    Invoke-RestMethod -Method 'GET' -Uri "https://atlas.microsoft.com/timezone/$type/json?subscription-key=$($ApiKey)&api-version=1.0&options=all&$($query)"
}