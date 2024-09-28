function Check-IntuneCertificates {
    <#
    .SYNOPSIS
    Checks for the presence of certificates in the specified certificate store, issued by a specified issuer, within a given timeout period.

    .DESCRIPTION
    This function waits for up to a specified timeout for certificates to be created in the specified certificate store, looking specifically for certificates issued by the provided issuer name. It logs the waiting process and the outcome, successfully finding the certificates or timing out.

    .PARAMETER CertStorePath
    The path of the certificate store to check for certificates. Default is the local machine's personal certificate store.

    .PARAMETER IssuerName
    The name of the issuer to check for in the certificates. Default is "CN=Microsoft Intune MDM Device CA".

    .PARAMETER Timeout
    The maximum amount of time, in seconds, to wait for the certificates. Default is 30 seconds.

    .EXAMPLE
    Check-IntuneCertificates
    Checks for certificates issued by Microsoft Intune in the local machine's personal certificate store with the default timeout of 30 seconds.

    .EXAMPLE
    Check-IntuneCertificates -CertStorePath 'Cert:\LocalMachine\My\' -IssuerName "CN=Microsoft Intune MDM Device CA" -Timeout 60
    Checks for certificates with a custom timeout of 60 seconds in the specified certificate store and issuer.

    .NOTES
    Ensure that the 'Write-EnhancedLog' function is defined in your environment for logging.
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false, HelpMessage = "Specify the certificate store path to check.")]
        [ValidateNotNullOrEmpty()]
        [string]$CertStorePath = 'Cert:\LocalMachine\My\',

        [Parameter(Mandatory = $false, HelpMessage = "Specify the issuer name to check.")]
        [ValidateNotNullOrEmpty()]
        [string]$IssuerName = "CN=Microsoft Intune MDM Device CA",

        [Parameter(Mandatory = $false, HelpMessage = "Specify the maximum time (in seconds) to wait for the certificate.")]
        [ValidateRange(1, 300)]
        [int]$Timeout = 30
    )

    Begin {
        Write-EnhancedLog -Message "Starting Check-IntuneCertificates function." -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters
        Write-EnhancedLog -Message "Waiting for certificates from issuer: $IssuerName in store: $CertStorePath" -Level "INFO"
    }

    Process {
        try {
            $remainingTime = $Timeout

            # Loop to wait for the certificate to appear, or until the timeout is reached
            while ($remainingTime -gt 0) {
                try {
                    $certificates = Get-ChildItem -Path $CertStorePath | Where-Object { $_.Issuer -match $IssuerName }
                }
                catch {
                    Write-EnhancedLog -Message "Error accessing certificates in path: $CertStorePath. Error: $($_.Exception.Message)" -Level "ERROR"
                    Handle-Error -ErrorRecord $_
                    return
                }

                if ($certificates) {
                    Write-EnhancedLog -Message "Certificate(s) found for issuer: $IssuerName." -Level "INFO"
                    break
                }

                Write-EnhancedLog -Message "Waiting... ($remainingTime seconds remaining)" -Level "INFO"
                Start-Sleep -Seconds 1
                $remainingTime--
            }

            # Check if the loop ended due to timeout
            if ($remainingTime -eq 0) {
                Write-EnhancedLog -Message "Timed out waiting for certificate from issuer: $IssuerName in store: $CertStorePath" -Level "WARNING"
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred during the certificate check process. Error: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            return
        }
    }

    End {
        Write-EnhancedLog -Message "Check-IntuneCertificates function has completed." -Level "Notice"
    }
}
