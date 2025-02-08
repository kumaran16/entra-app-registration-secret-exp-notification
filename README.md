# Expiring Secrets and Certificates Notification Script

This PowerShell script queries all application registrations in Entra (Azure AD), identifies secrets and certificates that are expiring within the next 30 days, and sends email notifications to the respective application owners. If no owner information is available, the script sends the notification to a predefined email address. Additionally, the script generates a summary of all expiring secrets and certificates and sends it to a predefined email address.

## Prerequisites

- AzureAD module
- Microsoft Graph PowerShell SDK
- SMTP server configuration for sending emails

## Configuration

Before running the script, configure the following parameters:

- `$DaysUntilExpiration`: The number of days until expiration to check for (default is 30).
- `$SmtpServer`: The SMTP server address for sending emails.
- `$From`: The email address from which notifications will be sent.
- `$DefaultEmail`: The email address to send notifications to if no owner information is available.

## Script Details

### Functions

#### `Send-ExpirationAlert`

Sends an email notification to the application owner or default email address.

**Parameters:**
- `To`: Recipient email address.
- `FirstName`: Recipient's first name.
- `AppName`: Application name.
- `SecretOrCertName`: Secret or certificate name.
- `SecretOrCertId`: Secret or certificate ID.
- `EndDate`: Expiration date.

#### `Send-SummaryEmail`

Sends a summary email of all expiring secrets and certificates.

**Parameters:**
- `To`: Recipient email address.
- `Body`: Email body content.

### Main Script

1. **Get the current date:**
   ```powershell
   $Now = Get-Date
2. Query all applications:
    ```powershell
    $Applications = Get-MgApplication -All
3. Initialize summary body:
   ```powershell
   $SummaryBody = @"
    <html>
    <body>
    <p>Hello,</p>
    <p>The following secrets and certificates are expiring in the next 30 days:</p>
    <table border='1'>
    <tr>
    <th>Application Name</th>
    <th>Secret or Certificate Name</th>
    <th>Secret or Certificate ID</th>
    <th>Expiration Date</th>
    </tr>
    "@
5. Process each application:
    Retrieve secrets and certificates.
    Check expiration dates.
    Send notifications to owners or default email.
    Add expiring secrets and certificates to the summary.
6. Close the HTML table and body:
     ```powershell
     $SummaryBody += @"
    </table>
    <p>Thank you,<br>Your IT Team</p>
    </body>
    </html>
    "@
 8. Send the summary email:
    ```powershell
    Send-SummaryEmail -To $DefaultEmail -Body $SummaryBody

**Usage and Example**
   
   Open PowerShell with administrative privileges.
      Run the script:
   
         .\exp-secrets-certs-email.ps1

         # Set default value for the number of days until expiration
         $DaysUntilExpiration = 30
         
         # Email configuration
         $SmtpServer = "smtpserver.yourdomain.com"
         $From = "alerts@yourdomain.com"
         $DefaultEmail = "admin_shared_mailbox@yourdomain.com"
         
         # Run the script
         .\exp-secrets-certs-email.ps1
