function Invoke-AzRestVmMetricsReport{
    [CmdletBinding(DefaultParameterSetName = 'Days')]
    param(
        [PSObject]$token
        ,
        [Parameter(Mandatory = $true)]
        $vm
        ,
        $Metric = @(
            'Percentage CPU'
            ,'CPU Credits Remaining'
            ,'CPU Credits Consumed'
            ,'OS Disk Read Bytes/sec'
            ,'OS Disk Write Bytes/sec'
            ,'OS Disk Read Operations/Sec'
            ,'OS Disk Write Operations/Sec'
            ,'OS Disk Queue Depth'
            ,'Premium OS Disk Cache Read Hit'
            ,'Data Disk Read Bytes/sec'
            ,'Data Disk Write Bytes/sec'
            ,'Data Disk Read Operations/Sec'
            ,'Data Disk Write Operations/Sec'
            ,'Data Disk Queue Depth'
            ,'Premium Data Disk Cache Read Hit'
            #,'Network In Total'
            #,'Network Out Total'
        )
        ,
        [Parameter(Mandatory = $true,
        ParameterSetName = 'Days')]
        [ValidateRange(1,30)]
        [int]$days
        ,
        [Parameter(Mandatory = $true,
        ParameterSetName = 'Today')]
        [switch]$today
        ,
        [Parameter(ParameterSetName = 'Today')]
        [Parameter(ParameterSetName = 'Days')]
        [switch]$OfficeHours
        ,
        [Parameter(Mandatory = $true,
        ParameterSetName = 'dateTime')]
        [datetime]$dateTimeBegin = (Get-Date).AddDays(-1).Date
        ,
        [Parameter(Mandatory = $true,
        ParameterSetName = 'dateTime')]
        [datetime]$dateTimeEnd = [datetime](Get-Date).adddays(-1).ToString('yyyy-MM-ddT23:59:59')
    )

    $splatToken = @{}
    If ($token){
        $splatToken.token = $token 
    }Else{
        $splatToken.token = Get-AzRestToken
    }

    $TimeBegin = '00:00:00'
    $TimeEnd = '23:59:59'
    If ($OfficeHours){
        $TimeBegin = '00:07:00'
        $TimeEnd = '18:59:59'    
    }

    #Skew days value so that at least one loop will pass
    switch ($PsCmdlet.ParameterSetName){
        'Days'      {$daysToProcess = $days}
        Default     {$daysToProcess = 1}
    }

    $Report = @{
        ResourceId = $vm.Id
        VmId = $vm.properties.vmid
        VmName = $vm.name
    }

    foreach ($mtp in $Metric){
        $AgregatedMetrics = @()
        for ($dayToProcess = 1; $dayToProcess -le $daysToProcess; $dayToProcess++){
            If ($PsCmdlet.ParameterSetName -eq 'Today'){
                $dateTimeBegin = (Get-Date).Date
                $Begin = "$($dateTimeBegin.ToString('yyyy-MM-dd'))T$($dateTimeBegin.TimeOfDay)Z"
                $End = "$($dateTimeEnd.ToString('yyyy-MM-dd'))T$($dateTimeEnd.TimeOfDay)Z"
            }
            If ($PsCmdlet.ParameterSetName -eq 'dateTime'){
                $Begin = "$($dateTimeBegin.ToString('yyyy-MM-dd'))T$($dateTimeBegin.TimeOfDay)Z"
                $End = "$($dateTimeEnd.ToString('yyyy-MM-dd'))T$($dateTimeEnd.TimeOfDay)Z"
            }
            Else{
                $dateTimeBegin = (Get-Date).AddDays(-$dayToProcess).Date
                $Begin = "$($dateTimeBegin.ToString('yyyy-MM-dd'))T$($TimeBegin)Z"
                $End = "$($dateTimeBegin.ToString('yyyy-MM-dd'))T$($TimeEnd)Z"
            }
            $timespan = "&timespan=$($Begin)/$($End)"
            $AM = Invoke-AzRestMetricsAgregate -InputObject (Get-AzRestMetrics -ResourceUri $vm.Id -Name $mtp -timespan $timespan @splatToken)
            $AM | Add-Member -NotePropertyName 'Begin' -NotePropertyValue $TimeBegin
            $AM | Add-Member -NotePropertyName 'End' -NotePropertyValue $TimeEnd
            $AM | Add-Member -NotePropertyName 'Date' -NotePropertyValue $dateTimeBegin.ToString('yyyy-MM-dd')
            $AgregatedMetrics += $AM
        }
        $Report[$mtp] = $AgregatedMetrics
    }

    $Report
}