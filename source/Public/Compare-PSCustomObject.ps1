function Compare-PSCustomObject {
    <#
        .SYNOPSIS
        Compares two PSCustomObject objects and returns the differences.

        .DESCRIPTION
        TODO

        .EXAMPLE
        TODO


        .PARAMETER ReferenceCustomObject
        PSCustomObject object containing the reference values.

        .PARAMETER ReferenceCustomObject
        PSCustomObject object containing the values to compare against the reference values.

        .PARAMETER IncludeEqual
        Defines if keys with matching values should be returned as well.

    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]

    param
    (
        [Parameter(Mandatory)]
        [PSCustomObject]$ReferenceCustomObject,

        [Parameter(Mandatory)]
        [PSCustomObject]$DifferenceCustomObject,

        [switch]$IncludeEqual
    )

    process {
        $ErrorActionPreference = 'Stop'

        # Loop through all keys in the reference object.
        [Object[]]$Results = $ReferenceCustomObject.PsObject.Properties.Name | ForEach-Object {
            $RefValue = $ReferenceCustomObject.$_
            $RefValueType = try { $RefValue.GetType().Name } catch { $null }
            
            # Add result for keys that doesn't exist in the difference object. 
            if ($null -eq $DifferenceCustomObject.$_) {
                New-ComparisonResult $_ $RefValueType $RefValue '=>' $null
            }
            else {
                $DifValue = $DifferenceCustomObject.$_
                $DifValueType = try { $DifValue.GetType().Name } catch { $null }
                # Warn if the values are not of the same type
                if ($RefValueType -ne $DifValueType) {
                    Write-Warning "Key $($FullPath -join '.') in the reference object is of type $RefValueType, but the corrosponding key in the difference object is of type $DifValueType. Cannot compare values."
                }
                # Add result if key values doesnt match
                elseif ($RefValue -cne $DifValue) {
                    New-ComparisonResult $_ $RefValueType $RefValue '!=' $DifValue
                }
                # Add result if key values match
                elseif ($IncludeEqual) {
                    New-ComparisonResult $_ $RefValueType $RefValue '==' $DifValue
                }
                
            }
        }
        # Add result for any keys that only exists in the difference object.
        $Results += $DifferenceCustomObject.PsObject.Properties.Name | ForEach-Object {
            if ($null -eq $DifferenceCustomObject.$_ -and $null -eq $ReferenceCustomObject.$_) {
                $DifValue = $DifferenceCustomObject.$_ 
                $DifValueType = $DifValue.GetType().Name
                New-ComparisonResult $_ $DifValueType $null '<=' $DifValue
            } 
        }
        if ($Results) {
            Write-Output $Results 
        }    
    }
}
