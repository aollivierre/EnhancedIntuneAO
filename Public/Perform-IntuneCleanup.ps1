function Perform-IntuneCleanup {
    <#
    .SYNOPSIS
    Performs an Intune cleanup by removing MDM certificates, task scheduler entries, and registry keys associated with Intune enrollment GUIDs.

    .DESCRIPTION
    This function first checks for Intune-related certificates, removes MDM certificates, and cleans up task scheduler entries, registry keys, and associated GUIDs related to Intune. It also performs checks before and after the cleanup to verify that the cleanup was successful. Finally, it provides a summary report of the cleanup process.

    .NOTES
    Assumes that `Check-IntuneCertificates`, `Remove-MDMCertificates`, `Get-ManagementGUID`, `Check-RegistryKeys`, `Check-TaskSchedulerEntriesAndTasks`, `Remove-TaskSchedulerEntriesAndTasks`, and `Remove-RegistryEntries` are defined elsewhere in the script or module.
    #>

    [CmdletBinding()]
    param ()

    Begin {
        # Initialize counters and summary table
        $successCount = 0
        $warningCount = 0
        $errorCount = 0
        $summaryTable = [System.Collections.Generic.List[PSCustomObject]]::new()

        Write-EnhancedLog -Message "Starting Intune cleanup process." -Level "Notice"
    }

    Process {
        try {
            # Check for Intune-related certificates before removal.
            Write-EnhancedLog -Message "Checking for Intune certificates before removal." -Level "INFO"
            Check-IntuneCertificates

            # Define the parameters for certificate removal in a hashtable and call with splatting.
            $certParams = @{
                CertStorePath = 'Cert:\LocalMachine\My\'
                IssuerName    = "CN=Microsoft Intune MDM Device CA"
            }

            Write-EnhancedLog -Message "Removing MDM certificates." -Level "INFO"
            Remove-MDMCertificates @certParams

            # Check for Intune-related certificates after removal.
            Write-EnhancedLog -Message "Re-checking for Intune certificates after removal." -Level "INFO"
            Check-IntuneCertificates

            # Obtain the current management GUIDs.
            Write-EnhancedLog -Message "Retrieving enrollment GUIDs." -Level "INFO"
            $EnrollmentGUIDs = Get-ManagementGUID

            if ($EnrollmentGUIDs.Count -eq 0) {
                Write-EnhancedLog -Message "No enrollment GUIDs found. Exiting cleanup process." -Level "Warning"
                $warningCount++
                return
            }

            foreach ($EnrollmentGUID in $EnrollmentGUIDs) {
                Write-EnhancedLog -Message "Processing cleanup for enrollment GUID: $EnrollmentGUID" -Level "INFO"

                # Check registry keys before cleanup.
                Write-EnhancedLog -Message "Checking registry keys before cleanup for GUID: $EnrollmentGUID." -Level "INFO"
                Check-RegistryKeys -EnrollmentGUIDs @($EnrollmentGUID)

                # Check task scheduler entries before cleanup.
                Write-EnhancedLog -Message "Checking task scheduler entries for GUID: $EnrollmentGUID." -Level "INFO"
                Check-TaskSchedulerEntriesAndTasks -EnrollmentGUID $EnrollmentGUID

                # Remove task scheduler entries.
                Write-EnhancedLog -Message "Removing task scheduler entries for GUID: $EnrollmentGUID." -Level "INFO"
                Remove-TaskSchedulerEntriesAndTasks -EnrollmentGUID $EnrollmentGUID

                # Verify task scheduler entries after removal.
                Write-EnhancedLog -Message "Verifying task scheduler entries cleanup for GUID: $EnrollmentGUID." -Level "INFO"
                Check-TaskSchedulerEntriesAndTasks -EnrollmentGUID $EnrollmentGUID

                # Remove registry entries associated with the GUID.
                Write-EnhancedLog -Message "Removing registry entries for GUID: $EnrollmentGUID." -Level "INFO"
                Remove-RegistryEntries -EnrollmentGUID $EnrollmentGUID

                # Verify registry cleanup after removal.
                Write-EnhancedLog -Message "Verifying registry cleanup for GUID: $EnrollmentGUID." -Level "INFO"
                Check-RegistryKeys -EnrollmentGUIDs @($EnrollmentGUID)

                # Add success record to the summary table
                $summaryTable.Add([PSCustomObject]@{
                    EnrollmentGUID = $EnrollmentGUID
                    Status         = "Success"
                })
                $successCount++
            }

            Write-EnhancedLog -Message "Intune cleanup process completed." -Level "Success" -ForegroundColor Green
        }
        catch {
            Write-EnhancedLog -Message "An error occurred during the Intune cleanup process. Error: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            $errorCount++
            $summaryTable.Add([PSCustomObject]@{
                EnrollmentGUID = $EnrollmentGUID
                Status         = "Failed"
            })
        }
    }

    End {
        # Final Summary Report
        Write-EnhancedLog -Message "----------------------------------------" -Level "INFO"
        Write-EnhancedLog -Message "Final Cleanup Summary Report" -Level "NOTICE"
        Write-EnhancedLog -Message "Total GUIDs processed: $($successCount + $warningCount + $errorCount)" -Level "INFO"
        Write-EnhancedLog -Message "Successfully processed GUIDs: $successCount" -Level "INFO"
        Write-EnhancedLog -Message "Warnings: $warningCount" -Level "WARNING"
        Write-EnhancedLog -Message "Failed GUIDs: $errorCount" -Level "ERROR"
        Write-EnhancedLog -Message "----------------------------------------" -Level "INFO"

        # Color-coded summary for the console
        Write-Host "----------------------------------------" -ForegroundColor White
        Write-Host "Final Intune Cleanup Summary Report" -ForegroundColor Cyan
        Write-Host "Total GUIDs processed: $($successCount + $warningCount + $errorCount)" -ForegroundColor White
        Write-Host "Successfully processed GUIDs: $successCount" -ForegroundColor Green
        Write-Host "Warnings: $warningCount" -ForegroundColor Yellow
        Write-Host "Failed GUIDs: $errorCount" -ForegroundColor Red
        Write-Host "----------------------------------------" -ForegroundColor White

        # Display the summary table of GUIDs and their statuses
        Write-Host "Intune Cleanup Summary:" -ForegroundColor Cyan
        $summaryTable | Format-Table -AutoSize

        # Optionally log the summary to the enhanced log as well
        foreach ($row in $summaryTable) {
            Write-EnhancedLog -Message "EnrollmentGUID: $($row.EnrollmentGUID), Status: $($row.Status)" -Level "INFO"
        }
    }
}
