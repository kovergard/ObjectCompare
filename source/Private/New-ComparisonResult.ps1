function New-ComparisonResult($Path, $Type, $RefValue, $SideIndicator, $DifValue) {
    [PSCustomObject][Ordered]@{
        Key             = $Path -join '.'
        Type            = $Type
        ReferenceValue  = $RefValue
        DifferenceValue = $DifValue
        SideIndicator   = $SideIndicator
    }
}
