function Invoke-AzRestMetricsAgregate {
    <#
    .SYNOPSIS
    Agregates multiple Azure metrics results. Regquires the Get-AzRestMetrics output as inputobject 
    
    .DESCRIPTION
    Agregates multiple Azure metrics results into a short report. The result is equal to Measure-Object -Allstats (PowerShell 6 and up). So:
    Count
    Minimum
    Maximum
    Average
    Sum
    StandardDeviation
    
    Requires the Get-AzRestMetrics output as inputobject
   #>
    Param(
        $InputObject
    ) 
    $ErrorActionPreference = 'SilentlyContinue'
    $AggregationTypeToProcess = @('average','total','maximum')
    #assuming ONE of the above type is provided..NOT a mix
    foreach ($at in $AggregationTypeToProcess){
        If (($InputObject.timeseries.data | get-member).name -contains $at){      
            #$InputObject.timeseries.data.where{([string]::Empty -eq $_.$at) -or ($null -eq $_.$at)}
            If ($PSVersionTable.PSVersion.Major -lt 6){
                #Legacy PowerShell version (<6). Do it the hard way :(
                $StdDevResult = Get-StandardDeviation ([pscustomobject]$InputObject.timeseries.data.where{$_.$at}).$at
                $MeasureObjectResult = [PSCustomObject]$InputObject.timeseries.data.where{$_.$at} | Measure-Object -Property $at -Average -Sum -Maximum -Minimum
                $MeasureObjectResult | Add-Member -NotePropertyName StandardDeviation -NotePropertyValue $StdDevResult.'Standard Deviation'
            }
            Else{
                $MeasureObjectResult = [PSCustomObject]$InputObject.timeseries.data.where{$_.$at} | Measure-Object -Property $at -AllStats # AllStats only works on >PS5
            }
            $95thPercentileResult = Get-Percentile -Sequence ([pscustomobject]$InputObject.timeseries.data.where{$_.$at}).$at -Percentile 0.95
            $MeasureObjectResult | Add-Member -NotePropertyName 95thPercentile -NotePropertyValue $95thPercentileResult
            $MeasureObjectResult
        }
    }
}