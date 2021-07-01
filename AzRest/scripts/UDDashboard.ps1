#requires -Version 6
<#
https://adamtheautomator.com/universal-dashboard-azure/
https://www.powershellgallery.com/packages/UniversalDashboard.Community/2.9.0
https://docs.universaldashboard.io/components/navigation
https://poshud.com/Home
https://ironmansoftware.com/powershell-universal-dashboard/


https://docs.microsoft.com/en-us/dotnet/api/system.drawing.color?view=netframework-4.7.2
#>

If (!(Get-Module -Name UniversalDashboard.Community -ListAvailable)){
    Install-Module -Name UniversalDashboard.Community -AcceptLicense -Repository PSGallery -force
}


$dayTimeBegin = '00:00:00'
$officeTimeBegin = '00:07:00'

$path = resolve-path -path 'c:\temp\trending'

$files = Get-ChildItem -Path $path -File
$metrics = @()
Foreach ($file in $files){
    $metrics += Get-Content $file.fullname | ConvertFrom-Json
}

$vms = $metrics | Select-Object -Property VMName,VmId,ResourceId -Unique

$Dashboard = New-UDDashboard -Title "Metrics" -Content {
    New-UDHeading -Text "Metrics" -Size 1
    
    <#
    New-UDChart -Title "Threads by Process" -Type Doughnut -RefreshInterval 5 -Endpoint {  
        Get-Process | ForEach-Object { [PSCustomObject]@{ Name = $_.Name; Threads = $_.Threads.Count } } | Out-UDChartData -DataProperty "Threads" -LabelProperty "Name"  
    } -Options @{  
         legend = @{  
             display = $false  
         }  
        }
           
    New-UDChart -Title "Percentage CPU" -Type Bar -Endpoint {  
        $clondalkinmetrics[0].metrics.'Percentage CPU'[0]  | Out-UDChartData -DataProperty "Average" -LabelProperty "Date"  
    } -Options @{  
         legend = @{  
             display = $false  
         }  
    }
    #>
    
    foreach ($vm in $vms){
        $vmMetrics = $metrics.where{$_.ResourceId -eq $vm.ResourceId} 
        $members = $vmMetrics | Get-Member
        $metricItems = $members | Where-Object {($_.MemberType -eq 'NoteProperty') -and ($_.Name -ne 'ResourceId') -and ($_.Name -ne 'VmId') -and ($_.Name -ne 'VmName')}
        foreach ($Item in $metricItems){
            Write-Verbose "$($vm.vmname): $($Item.name): Processing...."
            Try {
                $vmMetrics."$($Item.name)".Count
                If (( $vmMetrics."$($Item.name)".Count -ne $null) -or ( $vmMetrics."$($Item.name)".Count -ne 0)){
                    $showmetrics = $true
                }
                $dayItemMetrics = $vmMetrics."$($Item.name)".where{$_.Begin -eq $dayTimeBegin} | Sort-Object -Property Date -Unique
                $officeItemMetrics = $vmMetrics."$($Item.name)".where{$_.Begin -eq $officeTimeBegin} | Sort-Object -Property Date -Unique
                $itemMetrics =  $officeItemMetrics
                Write-Verbose "$($vm.vmname): $($Item.name): Has value count $($itemMetrics.Count)"
            }
            catch{
                $showmetrics = $false
                Write-Verbose "$($vm.vmname): $($Item.name): Skipping. Does not exist or has no count"
            }

            If ($showmetrics -eq $true){
                New-UDChart -Type line -Title "$($vm.vmname)-$($Item.name)" -Endpoint {
                    $itemMetrics |
                    ForEach-Object {
                        $MinStdDev = [Math]::Round($_.Average - $_.StandardDeviation, 2)
                        if ($MinStdDev -lt 0) {$MinStdDev = 0}
                        [PSCustomObject]@{  Date = $_.Date;
                                            Average = $_.Average;
                                            '95thPercentile' = $_.'95thPercentile';
                                            MinStdDev = $MinStdDev
                                            MaxStdDev = [Math]::Round($_.Average + $_.StandardDeviation, 2);
                                        }
                    } | 
                    Out-UDChartData -LabelProperty Date -Dataset @(
                        New-UdChartDataset -DataProperty "95thPercentile" -Label "95thPercentile" -BackgroundColor "empty" -HoverBackgroundColor "empty" -BorderColor "red" -BorderWidth 1
                        New-UdChartDataset -DataProperty "MaxStdDev" -Label "MaxStdDev" -BackgroundColor "#8014558C" -HoverBackgroundColor "#8014558C" -BorderWidth 1 -BorderColor "#8014558C"
                        New-UdChartDataset -DataProperty "Average" -Label "Average" -BackgroundColor "empty" -HoverBackgroundColor "empty" -BorderColor "black" -BorderWidth 3
                        New-UdChartDataset -DataProperty "MinStdDev" -Label "MinStdDev" -BackgroundColor "#8014558C" -HoverBackgroundColor "#8014558C" -BorderWidth 1 -BorderColor "#8014558C"
                    )
                }
            }
        }
    }
}

Start-UDDashboard -Dashboard $Dashboard -Port 10002