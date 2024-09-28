function Remove-RegistryEntries {
    <#
    .SYNOPSIS
    Removes specified registry entries under the Microsoft Enrollments key that match a given GUID.

    .DESCRIPTION
    The Remove-RegistryEntries function searches for and removes registry keys under "HKLM:\SOFTWARE\Microsoft\Enrollments" that match the specified EnrollmentGUID. It logs the process, including successes and warnings, using the Write-EnhancedLog function.

    .PARAMETER EnrollmentGUID
    The GUID of the enrollment entries to be removed from the registry.

    .EXAMPLE
    Remove-RegistryEntries -EnrollmentGUID "12345678-1234-1234-1234-1234567890ab"
    Removes all registry entries under Microsoft Enrollments that match the given GUID.

    .NOTES
    Uses the Write-EnhancedLog function for logging. Ensure this function is defined in your script or module.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the Enrollment GUID for the registry entries to be removed.")]
        [ValidateNotNullOrEmpty()]
        [string]$EnrollmentGUID
    )

    Begin {
        Write-EnhancedLog -Message "Starting registry entry removal for GUID: $EnrollmentGUID" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Define the registry path to search for enrollment entries
        $RegistryKeyPath = "HKLM:\SOFTWARE\Microsoft\Enrollments"

        Write-EnhancedLog -Message "Checking registry path: $RegistryKeyPath" -Level "INFO"
    }

    Process {
        try {
            if (Test-Path -Path $RegistryKeyPath) {
                # Get and remove registry entries matching the Enrollment GUID
                $registryEntries = Get-ChildItem -Path $RegistryKeyPath | Where-Object { $_.Name -match $EnrollmentGUID }

                if ($registryEntries.Count -gt 0) {
                    foreach ($entry in $registryEntries) {
                        try {
                            Remove-Item -Path $entry.PSPath -Recurse -Force -ErrorAction Stop
                            Write-EnhancedLog -Message "Removed registry entry for GUID: $EnrollmentGUID from path: $($entry.PSPath)" -Level "INFO"
                        }
                        catch {
                            Write-EnhancedLog -Message "Error removing registry entry at $($entry.PSPath). Error: $($_.Exception.Message)" -Level "ERROR"
                            Handle-Error -ErrorRecord $_
                        }
                    }
                }
                else {
                    Write-EnhancedLog -Message "No registry entries found matching GUID: $EnrollmentGUID under $RegistryKeyPath" -Level "WARNING"
                }
            }
            else {
                Write-EnhancedLog -Message "Registry key path $RegistryKeyPath not found." -Level "WARNING"
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while accessing the registry path $RegistryKeyPath. Error: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
        }
    }

    End {
        Write-EnhancedLog -Message "Completed registry entry removal for GUID: $EnrollmentGUID" -Level "Notice"
    }
}
