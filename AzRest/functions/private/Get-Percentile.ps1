function Get-Percentile {

    <#
    .SYNOPSIS
        Returns the specified percentile value for a given set of numbers.
     
    .DESCRIPTION
        This function expects a set of numbers passed as an array to the 'Sequence' parameter.  For a given percentile, passed as the 'Percentile' argument,
        it returns the calculated percentile value for the set of numbers.
     
    .PARAMETER Sequence
        A array of integer and/or decimal values the function uses as the data set.
    .PARAMETER Percentile
        The target percentile to be used by the function's algorithm. 
     
    .EXAMPLE
        $values = 98.2,96.5,92.0,97.8,100,95.6,93.3
        Get-Percentile -Sequence $values -Percentile 0.95
     
    .NOTES
        Author:  Jim Birley

    .LINK
        https://gist.github.com/jbirley/f4c7775007aabbcf6b67b9160276b198
    #>
    
        [CmdletBinding()]
        param (
            [Parameter(Mandatory)] 
            [Double[]]$Sequence
            ,
            [Parameter(Mandatory)]
            [Double]$Percentile
        )
       
        $Sequence = $Sequence | Sort-Object
        [int]$N = $Sequence.Length
        Write-Verbose "N is $N"
        [Double]$Num = ($N - 1) * $Percentile + 1
        Write-Verbose "Num is $Num"
        if ($num -eq 1) {
            return $Sequence[0]
        } elseif ($num -eq $N) {
            return $Sequence[$N-1]
        } else {
            $k = [Math]::Floor($Num)
            Write-Verbose "k is $k"
            [Double]$d = $num - $k
            Write-Verbose "d is $d"
            return $Sequence[$k - 1] + $d * ($Sequence[$k] - $Sequence[$k - 1])
        }
    }