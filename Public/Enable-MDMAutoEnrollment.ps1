function Enable-MDMAutoEnrollment {
    <#
    .SYNOPSIS
    Enables MDM AutoEnrollment by creating necessary registry entries and invoking the enrollment process.

    .DESCRIPTION
    This function checks if the required registry key and property for MDM AutoEnrollment are present. If not, it creates them and invokes the device enrollment process using `deviceenroller.exe`.

    .NOTES
    Ensure the 'Write-EnhancedLog' function is defined for logging, and the `Check-IntuneCertificates` function is available for certificate verification after enrollment.
    #>

    [CmdletBinding()]
    Param()

    Begin {
        Write-EnhancedLog -Message "Starting MDM AutoEnrollment process." -Level "Notice"
    }

    Process {
        try {
            $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM"

            # Check if the registry key exists
            if (-not (Test-Path $registryPath)) {
                Write-EnhancedLog -Message "Creating registry key for MDM AutoEnrollment: $registryPath" -Level "INFO"
                New-Item -Path $registryPath -ErrorAction Stop | Out-Null
            }
            else {
                Write-EnhancedLog -Message "Registry key for MDM AutoEnrollment already exists. Skipping creation." -Level "INFO"
            }

            # Check if the AutoEnrollMDM property exists
            try {
                $propertyExists = [bool](Get-ItemProperty -Path $registryPath -Name AutoEnrollMDM -ErrorAction Stop)
            }
            catch {
                $propertyExists = $false
            }

            # Set the AutoEnrollMDM property if it doesn't exist
            if (-not $propertyExists) {
                Write-EnhancedLog -Message "Setting AutoEnrollMDM property in $registryPath." -Level "INFO"
                New-ItemProperty -Path $registryPath -Name AutoEnrollMDM -Value 1 -ErrorAction Stop | Out-Null
            }
            else {
                Write-EnhancedLog -Message "AutoEnrollMDM property already exists. Skipping." -Level "INFO"
            }

            # Invoke the device enrollment process
            Write-EnhancedLog -Message "Invoking device enrollment process with deviceenroller.exe." -Level "INFO"
            & "$env:windir\system32\deviceenroller.exe" /c /AutoEnrollMDM

            Write-EnhancedLog -Message "MDM AutoEnrollment process completed successfully." -Level "Success"
        }
        catch {
            Write-EnhancedLog -Message "An error occurred during the MDM AutoEnrollment process. Error: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "MDM AutoEnrollment function has completed." -Level "Notice"

        # Optional post-check for certificates after enrollment
        Write-EnhancedLog -Message "Checking for Intune certificates post enrollment." -Level "INFO"
        Check-IntuneCertificates
    }
}

# Example invocation
# Enable-MDMAutoEnrollment
