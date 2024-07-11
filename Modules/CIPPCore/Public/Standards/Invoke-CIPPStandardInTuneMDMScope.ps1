function Invoke-CIPPStandardInTuneMDMScope {
    <#
    .FUNCTIONALITY
        Internal
    .COMPONENT
        (APIName) InTuneMDMScope
    .SYNOPSIS
        (Label) Set MDM scope
    .DESCRIPTION
        (Helptext) Sets the MDM scope for the tenant.
        (DocsDescription) Sets the MDM scope for the tenant.
    .NOTES
        CAT
            Intune Standards
        TAG
            "lowimpact"
        ADDEDCOMPONENT
            {"type":"Select","name":"standards.InTuneMDMScope.appliesTo","label":"MDM scope","values":[{"label":"All","value":"all"},{"label":"None","value":"none"}]}
        IMPACT
            Low Impact
        POWERSHELLEQUIVALENT
            InTune Automatic Enrollment
        RECOMMENDEDBY
        UPDATECOMMENTBLOCK
            Run the Tools\Update-StandardsComments.ps1 script to update this comment block
    .LINK
        https://docs.cipp.app/user-documentation/tenant/standards/edit-standards
    #>

    param ($Tenant, $Settings)
    $CurrentState = New-GraphGetRequest -Uri 'https://graph.microsoft.com/beta/policies/mobileDeviceManagementPolicies/0000000a-0000-0000-c000-000000000000' -TenantID $Tenant |
        Select-Object -Property appliesTo, complianceUrl, discoveryUrl, termsOfUseUrl

    $StateIsCorrect = ($CurrentState.appliesTo -eq $Settings.appliesTo)

    if ($Settings.remediate -eq $true) {
        if ($StateIsCorrect -eq $true) {
            Write-LogMessage -API 'Standards' -Message 'InTune MDM Scope is already correct' -Sev Info
        } else {
            $GraphParam = @{
                Uri = 'https://graph.microsoft.com/beta/policies/mobileDeviceManagementPolicies/0000000a-0000-0000-c000-000000000000'
                ContentType = 'application/json'
                TenantID = $Tenant
                Body = @{
                    appliesTo = $Settings.appliesTo
                }
            }

            try {
                New-GraphPostRequest @GraphParam
                Write-LogMessage -API 'Standards' -Message 'Successfully set the InTune MDM Scope to correct' -Sev Info
            } catch {
                $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
                Write-LogMessage -API 'Standards' -Message "Failed to set the InTune MDM Scope to correct. Error: $ErrorMessage" -Sev Error
            }
        }
    }

    if ($Settings.alert -eq $true) {
        if ($StateIsCorrect -eq $true) {
            Write-LogMessage -API 'Standards' -Message 'InTune MDM Scope is correct' -Sev Info
        } else {
            Write-LogMessage -API 'Standards' -Message 'InTune MDM Scope is not correct' -Sev Alert
        }
    }

    if ($Settings.report -eq $true) {
        Add-CIPPBPAField -FieldName 'InTuneMDMScope' -FieldValue $StateIsCorrect -StoreAs bool -Tenant $Tenant
    }
}
