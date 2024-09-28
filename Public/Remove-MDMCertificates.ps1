function Remove-MDMCertificates {
    <#
    .SYNOPSIS
    Removes MDM certificates from the specified certificate store based on issuer name.

    .DESCRIPTION
    The Remove-MDMCertificates function searches for and removes certificates from the specified certificate store path that are issued by the specified issuer, logging each removal action.

    .PARAMETER CertStorePath
    The path of the certificate store from which to remove certificates.

    .PARAMETER IssuerName
    The name of the issuer whose certificates should be removed.

    .EXAMPLE
    $parameters = @{
        CertStorePath = 'Cert:\LocalMachine\My\'
        IssuerName = "CN=Microsoft Intune MDM Device CA"
    }
    Remove-MDMCertificates @parameters
    Removes all MDM certificates issued by Microsoft Intune from the LocalMachine's My certificate store.

    .NOTES
    Uses Write-EnhancedLog for detailed logging.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Provide the certificate store path.")]
        [ValidateNotNullOrEmpty()]
        [string]$CertStorePath,

        [Parameter(Mandatory = $true, HelpMessage = "Provide the issuer name to filter certificates by.")]
        [ValidateNotNullOrEmpty()]
        [string]$IssuerName
    )

    Begin {
        Write-EnhancedLog -Message "Starting Remove-MDMCertificates function" -Level "Notice"
        Log-Params -Params $PSCmdlet.MyInvocation.BoundParameters

        # Validate the certificate store path
        if (-not (Test-Path $CertStorePath)) {
            throw "The specified certificate store path does not exist: $CertStorePath"
        }

        Write-EnhancedLog -Message "Searching for certificates in store: $CertStorePath with issuer: $IssuerName" -Level "INFO"
    }

    Process {
        try {
            # Retrieve certificates issued by the specified issuer
            $mdmCerts = Get-ChildItem -Path $CertStorePath | Where-Object Issuer -eq $IssuerName
            
            if ($mdmCerts.Count -eq 0) {
                Write-EnhancedLog -Message "No certificates found from issuer: $IssuerName in $CertStorePath" -Level "Warning"
                return
            }

            # Loop through and remove each certificate
            foreach ($cert in $mdmCerts) {
                Write-EnhancedLog -Message "Removing certificate issued by $IssuerName $($cert.Subject)" -Level "INFO"
                Remove-Item -Path $cert.PSPath -ErrorAction Stop
                Write-EnhancedLog -Message "Successfully removed certificate: $($cert.Subject)" -Level "INFO"
            }
        }
        catch {
            Write-EnhancedLog -Message "An error occurred while removing certificates: $($_.Exception.Message)" -Level "ERROR"
            Handle-Error -ErrorRecord $_
            throw
        }
    }

    End {
        Write-EnhancedLog -Message "Completed Remove-MDMCertificates function" -Level "Notice"
    }
}
