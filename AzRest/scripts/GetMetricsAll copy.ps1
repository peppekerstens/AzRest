#requires -Version 7

#voor 6 PS sessies tegelijk
$path = resolve-path -path 'c:\temp\metrics'
$days = 5
$limit = 5
#get metrics data
import-Module AzRest
$subs = Get-AzRestSubscription
$subs | ForEach-Object -ThrottleLimit $limit -Parallel {
    write-host "Using sub:$($_.DisplayName) path:$($using:path) days:$($using:days)"
    $argumentList = @{
        ArgumentList = "-command import-module AzRest;Write-host `"Using sub:$($_.DisplayName) path:$($using:path) days:$($using:days)`";Get-AzContext;Start-Sleep 2;Get-MetricsParallel -sub $($_) -path $($using:path) -days $($using:days);#start-sleep 5"
    }
    start-process -FilePath pwsh.exe -ArgumentList "-command import-module AzRest';Write-host `"Using sub:$($_.DisplayName) path:$($using:path) days:$($using:days)`";Get-AzContext;Start-Sleep 2;Get-MetricsParallel -sub $($_) -path $($using:path) -days $($using:days);#start-sleep 5" -wait
}
