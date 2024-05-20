function Compare-Hashtable {
    <#
        .SYNOPSIS
        Compares two hashtables and returns the differences.

        .DESCRIPTION
        Runs through two hashtables, comparing the vaules of all keys inside. Each difference found will result in an object containing values being returned.
        
        Arrays inside the hashtables are handled as well, however they must be arranged in the same order in both sides, or values will be shown as mismatched.

        .EXAMPLE
        Compare-Hashtable -ReferenceHashtable $Hash1 -DifferenceHashtable $Hash2 -IncludeEqual

        Compares the value of each key inside $Hash1 and $Hash2, and returns the result of the comparison, including values that are equal.

        .PARAMETER ReferenceHashtable
        Hashtable containing the reference values.

        .PARAMETER DifferenceHashtable
        Hashtable containing the values to compare against the reference values.

        .PARAMETER IncludeEqual
        Defines if keys with matching values should be returned as well.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    Param (
        [Parameter(Mandatory)]
        [Hashtable]$ReferenceHashtable,

        [Parameter(Mandatory)]
        [Hashtable]$DifferenceHashtable,

        [switch]$IncludeEqual,

        # Internal parameter used to show the full path for nested hashtables.
        [Parameter(DontShow)]
        [string[]]$Path

        # TODO Additional switches: -ExcludeDifferent, -CaseSensitive 
    )

    $ErrorActionPreference = 'Stop'

    # Loop through all keys in the reference hashtable.
    [Object[]]$Results = $ReferenceHashtable.Keys | ForEach-Object {
        $RefValue = $ReferenceHashtable[$_]
        $RefValueType = try { $RefValue.GetType().Name } catch { $null }
        $FullPath = $Path + $_
        #Write-Verbose "Examining key $($FullPath -join '.')"
        # Add result for keys that doesn't exist in the difference hashtable. 
        if (-not $DifferenceHashtable.ContainsKey($_)) {
            New-ComparisonResult $FullPath $RefValueType $RefValue '=>' $null
        }
        else {
            $DifValue = $DifferenceHashtable[$_]
            $DifValueType = try { $DifValue.GetType().Name } catch { $null }
            # Warn if the values are not of the same type
            if ($RefValueType -ne $DifValueType) {
                Write-Warning "Key $($FullPath -join '.') in the reference object is of type $RefValueType, but the corrosponding key in the difference object is of type $DifValueType. Cannot compare values."
            }
            # Handle nested arrays
            elseif ($RefValueType -eq 'Object[]') {
                $i = 0
                $RefValueCount = $RefValue.Count
                $DifValueCount = $DifValue.Count
                if ($RefValueCount -ne $DifValueCount) {
                    Write-Warning "Key $($FullPath -join '.') in the reference object is of type $RefValueType with $RefValueCount entries, but the corrosponding key in the difference object only have $DifValueCount entries. Cannot compare values."                    
                }
                else {
                    while ($i -lt $RefValueCount) {
                        $RefArrayValue = $RefValue[$i]
                        $RefArrayValueType = $RefArrayValue.GetType().Name
                        $DifArrayValue = $DifValue[$i]
                        $DifArrayValueType = $DifArrayValue.GetType().Name
                        $ArrayPath = $FullPath + "[$i]"
                        if ($RefArrayValueType -ne $DifArrayValueType) {
                            Write-Warning "Key $ArrayPath in the reference object is of type $RefArrayValueType, but the corrosponding key in the difference object is of type $DifArrayValueType. Cannot compare values."
                        }
                        elseif ($RefArrayValueType -eq 'Hashtable') {
                            Compare-Hashtable -ReferenceHashtable $RefArrayValue -DifferenceHashtable $DifArrayValue -Path $ArrayPath -IncludeEqual:$IncludeEqual
                        }
                        elseif ($RefArrayValue -cne $DifArrayValue) {
                            New-ComparisonResult $ArrayPath $RefArrayValueType $RefArrayValue '!=' $DifArrayValue
                        }
                        elseif ($IncludeEqual) {
                            New-ComparisonResult $ArrayPath $RefArrayValueType $RefArrayValue '==' $DifArrayValue
                        }
                        $i++
                    }
                }
            }
            # Handle nested hashtables
            elseif ($RefValueType -eq 'Hashtable') {
                Compare-Hashtable -ReferenceHashtable $RefValue -DifferenceHashtable $DifValue -Path $FullPath -IncludeEqual:$IncludeEqual  
            }
            # Add result if key values doesnt match
            elseif ($RefValue -cne $DifValue) {
                New-ComparisonResult $FullPath $RefValueType $RefValue '!=' $DifValue
            }
            # Add result if key values match
            elseif ($IncludeEqual) {
                New-ComparisonResult $FullPath $RefValueType $RefValue '==' $DifValue
            }
            
        }
    }
    # Add result for any keys that only exists in the difference hashtable.
    $Results += $DifferenceHashtable.Keys | ForEach-Object {
        if (!$ReferenceHashtable.ContainsKey($_) -and $DifferenceHashtable.ContainsKey($_)) {
            $DifValue = $DifferenceHashtable[$_]
            $DifValueType = $DifValue.GetType().Name
            New-ComparisonResult $_ $DifValueType $null '<=' $DifValue
        } 
    }
    if ($Results) {
        Write-Output $Results 
    }
} 