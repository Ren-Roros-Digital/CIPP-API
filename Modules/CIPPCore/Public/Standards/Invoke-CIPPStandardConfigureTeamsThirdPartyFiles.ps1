function Invoke-CIPPStandardConfigureTeamsThirdPartyFiles {
    <#
    .FUNCTIONALITY
    Internal
    #>

    param($Tenant, $Settings)
    $CurrentSetting = New-TeamsAPIGetRequest -Uri "https://api.interfaces.records.teams.microsoft.com/Skype.Policy/Tenants/$($Tenant)/configurations/TeamsClientConfiguration/configuration/Global" -tenantid $tenant |
        Select-Object AllowShareFile, AllowDropBox, AllowBox, AllowGoogleDrive, AllowEgnyte

    $StateIsCorrect = $CurrentSetting.AllowShareFile -eq $Settings.AllowShareFile -and
                      $CurrentSetting.AllowDropBox -eq $Settings.AllowDropBox -and
                      $CurrentSetting.AllowBox -eq $Settings.AllowBox -and
                      $CurrentSetting.AllowGoogleDrive -eq $Settings.AllowGoogleDrive -and
                      $CurrentSetting.AllowEgnyte -eq $Settings.AllowEgnyte

    if ($Settings.remediate) {
        if ($StateIsCorrect) {
            Write-LogMessage -API 'Standards' -Tenant $tenant -message 'Microsoft Teams Third Party Files are already configured.' -sev Info
        } else {
            Write-LogMessage -API 'Standards' -Tenant $tenant -message 'Remediating Microsoft Teams Third Party Files.' -sev Info
            $body = @{
                "AllowShareFile"    = $Settings.AllowShareFile
                "AllowDropBox"      = $Settings.AllowDropBox
                "AllowBox"          = $Settings.AllowBox
                "AllowGoogleDrive"  = $Settings.AllowGoogleDrive
                "AllowEgnyte"       = $Settings.AllowEgnyte
            }
    
            try {
                $params = @{
                    Uri       = "https://api.interfaces.records.teams.microsoft.com/Skype.Policy/Tenants/$($Tenant)/configurations/TeamsClientConfiguration/configuration/Global"
                    TenantId  = $tenant
                    Body      = $body
                }
                New-TeamsAPIPOSTRequest @params
            } catch {
                Write-LogMessage -API 'Standards' -Tenant $tenant -message "Failed to set Microsoft Teams Third Party Files settings. Error: $($_.exception.message)" -sev Error
            }
        }
    }

    if ($Settings.alert) {
        if ($StateIsCorrect) {
            Write-LogMessage -API 'Standards' -Tenant $tenant -message 'Microsoft Teams Third Party Files are configured.' -sev Info
        } else {
            Write-LogMessage -API 'Standards' -Tenant $tenant -message 'Microsoft Teams Third Party Files are not configured.' -sev Alert
        }
    }

    if ($Settings.report) {
        Add-CIPPBPAField -FieldName 'TeamsThirdPartyFiles' -FieldValue [bool]$StateIsCorrect -StoreAs bool -Tenant $tenant
    }
}
