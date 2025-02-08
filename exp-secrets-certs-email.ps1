# Set default value for the number of days until expiration
$DaysUntilExpiration = 30

# Email configuration
$SmtpServer = "smtpserver.yourdomain.com"
$From = "alerts@yourdomain.com"
#$HelpdeskEmail = "helpdesk@yourdomain.com"
$DefaultEmail = "admin_shared_mailbox@yourdomain.com"

# Function to send email
function Send-ExpirationAlert {
    param (
        [string]$To,
        [string]$FirstName,
        [string]$AppName,
        [string]$SecretOrCertName,
        [string]$SecretOrCertId,
        [datetime]$EndDate
    )

    $Subject = "Alert: Secret or Certificate Expiration Notice for $AppName"
    $Body = @"
<html>
<body>
<p>Hello $FirstName,</p>
<p>This is a notification that the secret or certificate named '$SecretOrCertName' for the application '$AppName' will expire on $($EndDate.ToShortDateString()).</p>
<p>Please contact your Entra (previously known as Azure AD) Administrators and take the necessary actions to renew or replace the secret or certificate before it expires.</p>
<p>Details to provide the administrators:</p>
<ul>
<li>Application Name: $AppName</li>
<li>Secret or Certificate Name: $SecretOrCertName</li>
<li>Secret or Certificate ID: $SecretOrCertId</li>
<li>Expiration Date: $($EndDate.ToShortDateString())</li>
</ul>
<p><span style="color: red;">Please do not reply to this email, this mailbox is not monitored.</span></p>
<p>Thank you,<br>Your IT Team</p>
</body>
</html>
"@

    Send-MailMessage -SmtpServer $SmtpServer -From $From -To $To -Subject $Subject -Body $Body -BodyAsHtml
}

# Function to send summary email
function Send-SummaryEmail {
    param (
        [string]$To,
        [string]$Body
    )

    $Subject = "Summary: Secrets and Certificates Expiring in the Next 30 Days"
    Send-MailMessage -SmtpServer $SmtpServer -From $From -To $To -Subject $Subject -Body $Body -BodyAsHtml
}

# Get the current date
$Now = Get-Date

# Query all applications
$Applications = Get-MgApplication -All

# Initialize a variable to store the summary of expiring secrets and certificates
$SummaryBody = @"
<html>
<body>
<p>Hello,</p>
<p>The following secrets and certificates are expiring in the next 30 days:</p>
<table border="1">
<tr>
<th>Application Name</th>
<th>Secret or Certificate Name</th>
<th>Secret or Certificate ID</th>
<th>Expiration Date</th>
</tr>
"@

# Process each application
foreach ($App in $Applications) {
    $AppName = $App.DisplayName
    $AppID   = $App.Id
    $ApplID  = $App.AppId

    $AppCreds = Get-MgApplication -ApplicationId $AppID
    $Secrets = $AppCreds.PasswordCredentials
    $Certs   = $AppCreds.KeyCredentials

    foreach ($Secret in $Secrets) {
        $StartDate  = $Secret.StartDateTime
        $EndDate    = $Secret.EndDateTime
        $SecretName = $Secret.DisplayName
        $SecretId   = $Secret.KeyId

        $Owners = Get-MgApplicationOwner -ApplicationId $App.Id

        if ($Owners.Count -eq 0) {
            # No owner information, send to default email
            $FirstName = "Admin"
            Send-ExpirationAlert -To $DefaultEmail -FirstName $FirstName -AppName $AppName -SecretOrCertName $SecretName -SecretOrCertId $SecretId -EndDate $EndDate
        } else {
            foreach ($Owner in $Owners) {
                $Username = $Owner.AdditionalProperties.userPrincipalName
                $OwnerID  = $Owner.Id

                if ($null -eq $Username) {
                    $Username = $Owner.AdditionalProperties.displayName
                    if ($null -eq $Username) {
                        $Username = '**<This is an Application>**'
                    }
                }

                # Extract first name from givenName or user principal name
                $FirstName = $Owner.AdditionalProperties.givenName
                if ($null -eq $FirstName -or $FirstName -eq '') {
                    $FirstName = $Username.Split('@')[0].Split('.')[0]
                }

                $RemainingDaysCount = ($EndDate - $Now).Days

                if ($RemainingDaysCount -le $DaysUntilExpiration -and $RemainingDaysCount -ge 0) {
                    if ($Username -ne '<<No Owner>>') {
                        Send-ExpirationAlert -To $Username -FirstName $FirstName -AppName $AppName -SecretOrCertName $SecretName -SecretOrCertId $SecretId -EndDate $EndDate
                    }
                }
            }
        }

        # Add to summary if expiring in the next 30 days
        if ($RemainingDaysCount -le $DaysUntilExpiration -and $RemainingDaysCount -ge 0) {
            $SummaryBody += @"
<tr>
<td>$AppName</td>
<td>$SecretName</td>
<td>$SecretId</td>
<td>$($EndDate.ToShortDateString())</td>
</tr>
"@
        }
    }

    foreach ($Cert in $Certs) {
        $StartDate  = $Cert.StartDateTime
        $EndDate    = $Cert.EndDateTime
        $CertName   = $Cert.DisplayName
        $CertId     = $Cert.KeyId

        $Owners = Get-MgApplicationOwner -ApplicationId $App.Id

        if ($Owners.Count -eq 0) {
            # No owner information, send to default email
            $FirstName = "Admin"
            Send-ExpirationAlert -To $DefaultEmail -FirstName $FirstName -AppName $AppName -SecretOrCertName $CertName -SecretOrCertId $CertId -EndDate $EndDate
        } else {
            foreach ($Owner in $Owners) {
                $Username = $Owner.AdditionalProperties.userPrincipalName
                $OwnerID  = $Owner.Id

                if ($null -eq $Username) {
                    $Username = $Owner.AdditionalProperties.displayName
                    if ($null -eq $Username) {
                        $Username = '**<This is an Application>**'
                    }
                }

                # Extract first name from givenName or user principal name
                $FirstName = $Owner.AdditionalProperties.givenName
                if ($null -eq $FirstName -or $FirstName -eq '') {
                    $FirstName = $Username.Split('@')[0].Split('.')[0]
                }

                $RemainingDaysCount = ($EndDate - $Now).Days

                if ($RemainingDaysCount -le $DaysUntilExpiration -and $RemainingDaysCount -ge 0) {
                    if ($Username -ne '<<No Owner>>') {
                        Send-ExpirationAlert -To $Username -FirstName $FirstName -AppName $AppName -SecretOrCertName $CertName -SecretOrCertId $CertId -EndDate $EndDate
                    }
                }
            }
        }

        # Add to summary if expiring in the next 30 days
        if ($RemainingDaysCount -le $DaysUntilExpiration -and $RemainingDaysCount -ge 0) {
            $SummaryBody += @"
<tr>
<td>$AppName</td>
<td>$CertName</td>
<td>$CertId</td>
<td>$($EndDate.ToShortDateString())</td>
</tr>
"@
        }
    }
}

# Close the HTML table and body
$SummaryBody += @"
</table>
<p>Thank you,<br>Your IT Team</p>
</body>
</html>
"@

# Send the summary email
Send-SummaryEmail -To $DefaultEmail -Body $SummaryBody
