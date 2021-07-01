$ScriptPath = Split-Path $MyInvocation.MyCommand.Path
write-verbose "Loading data from $($ScriptPath)"

if(Test-Path "$ScriptPath\Functions\Private"){
    #write-verbose "Loading Private Functions"
    $PrivateFunctions = Get-ChildItem "$ScriptPath\Functions\Private" -Filter *.ps1 -Recurse| Where-Object { $_.Name -notlike '_*' -and $_.Name -notlike '*.tests.ps1'} | Select-Object -Expand FullName
    foreach ($prFunction in $PrivateFunctions){
        write-verbose "importing private function $($prFunction)"
        try{
            . $prFunction
        }catch{
            write-warning $_
        }
    }
}

if(Test-Path "$ScriptPath\Functions\public"){
    #write-verbose "Loading Public Functions"
    $PublicFunctions = Get-ChildItem "$ScriptPath\Functions\public" -Filter *.ps1 -Recurse | Where-Object { $_.Name -notlike '_*' -and $_.Name -notlike '*.tests.ps1'} | Select-Object -Expand FullName
    foreach ($puFunction in $PublicFunctions){
        write-verbose "importing public function $($puFunction)"
        try{
            . $puFunction
        }catch{
            write-warning $_
        }
    }
}


if(Test-Path "$ScriptPath\workflows"){
    if(($PSVersionTable.PSVersion.Major -ge 3) -and ($PSVersionTable.PSVersion.Major -le 5)){ 
        $PublicWorkflows = Get-ChildItem "$ScriptPath\workflows" -Filter *.ps1 -Recurse | Where-Object { $_.Name -notlike '_*' -and $_.Name -notlike '*.tests.ps1'} | Select-Object -Expand FullName
        foreach ($puWorkflow in $PublicWorkflows){
            write-verbose "importing public function $($puWorkflow)"
            try{
                . $puWorkflow
            }catch{
                write-warning $_
            }
        }
    }
}Else{
   Write-Warning "Workflows are not supported in PowerShell version $($PSVersionTable.PSVersion.Major). Some functions may not be present/work"
}