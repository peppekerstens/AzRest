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


$type = 'OfficeHours' #OfficeHours or 'Daily'

Switch ($type) {
    'Daily'         {$TimeBegin = '00:00:00'}
    'OfficeHours'   {$TimeBegin = '00:07:00'}
}

$path = resolve-path -path 'C:\temp\metrics\'

$files = Get-ChildItem -Path $path -File
$metrics = @()
Foreach ($file in $files){
    $metrics += Get-Content $file.fullname | ConvertFrom-Json
}

$vms = $metrics | Select-Object -Property VMName,VmId,ResourceId -Unique

#configure side menu
$Pages = @()
$UDSideNav = @()
foreach ($vm in $vms){
    $vmMetrics = $metrics.where{$_.ResourceId -eq $vm.ResourceId} 
    $members = $vmMetrics | Get-Member
    $metricItems = $members | Where-Object {($_.MemberType -eq 'NoteProperty') -and ($_.Name -ne 'ResourceId') -and ($_.Name -ne 'VmId') -and ($_.Name -ne 'VmName')}
    $UDSideNavItem = @()
    foreach ($Item in $metricItems){
        Write-Verbose "$($vm.vmname): $($Item.name): Processing...."
        Try {
            $vmMetrics."$($Item.name)".Count
            If (( $vmMetrics."$($Item.name)".Count -ne $null) -or ( $vmMetrics."$($Item.name)".Count -ne 0)){
                $hasItemMetrics = $true
            }

            $itemMetrics = $vmMetrics."$($Item.name)".where{$_.Begin -eq $TimeBegin} | Sort-Object -Property Date -Unique
            Write-Verbose "$($vm.vmname): $($Item.name): Has value count $($itemMetrics.Count)"
        }
        catch{
            $hasItemMetrics = $false
            Write-Verbose "$($vm.vmname): $($Item.name): Skipping. Does not exist or has no count"
        }

        If ($hasItemMetrics -eq $true){
            $metricItemName = ($Item.name -replace " ") -replace "/"
            $UDSideNavItem += @{
                Text = $Item.name
                PageName = "$($vm.VmId)_$($metricItemName)"
            }
            $Page = New-UDPage -Name "$($vm.VmId)_$($metricItemName)" -Content {
                #New-UDHeading -Text "$($vm.VmId) $($Item.name)" -Size 3
                
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
            $pages += $Page
        }
    }

    $UDSideNav += [PSCustomObject]@{
        Text = $vm.VmName
        Children = $UDSideNavItem
    }
}

$Navigation = New-UDSideNav -Content {
    foreach ($UDSideNavItem in $UDSideNav){
        If ($UDSideNavItem.Children){
            New-UDSideNavItem -Text $UDSideNavItem.Text -Children {
                Foreach ($UDSideNavItemChild in $UDSideNavItem.Children){
                    If ($UDSideNavItemChild.PageName){
                        New-UDSideNavItem -Text "$($UDSideNavItemChild.Text)" -PageName "$($UDSideNavItemChild.PageName)" -Icon User
                    }
                }
            }
        }
    }
} #-Fixed

$Dashboard = New-UDDashboard -Title "$($type) Metrics" -Pages $pages -Navigation $Navigation

Stop-UDDashboard -Port 10002
Sleep 5
Stop-UDDashboard -Port 10002
Sleep 5
Start-UDDashboard -Dashboard $Dashboard -Port 10002