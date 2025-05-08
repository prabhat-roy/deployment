// groovy/Email.groovy

def archiveAndEmailReports = {
    echo "[INFO] Archiving reports and sending email..."

    // Step 1: Archive all reports in standard directories (adjust patterns if needed)
    echo "[INFO] Archiving common report types..."
    archiveArtifacts artifacts: '**/reports/**/*.html, **/reports/**/*.xml, **/reports/**/*.csv, **/zap_reports/*.html, **/test-results/*.xml', allowEmptyArchive: true

    // Step 2: Fetch SMTP and email details from Jenkins credentials
    withCredentials([
        string(credentialsId: 'smtp-username', variable: 'SMTP_USERNAME'),
        string(credentialsId: 'smtp-password', variable: 'SMTP_PASSWORD'),
        string(credentialsId: 'smtp-server', variable: 'SMTP_SERVER'),
        string(credentialsId: 'smtp-port', variable: 'SMTP_PORT'),
        string(credentialsId: 'email-from', variable: 'EMAIL_FROM'),
        string(credentialsId: 'email-to', variable: 'EMAIL_TO')
    ]) {
        def subject = "[Build #${env.BUILD_NUMBER}] Reports - Security & Test Artifacts"
        def body = """
            <p>Hi Team,</p>
            <p>Attached are the reports generated from build <b>#${env.BUILD_NUMBER}</b>.</p>
            <p>Regards,<br/>CI/CD Pipeline</p>
        """

        // Step 3: Collect all artifacts
        def reportFiles = findFiles(glob: '**/reports/**/*.html')
        if (reportFiles.size() == 0) {
            echo "[WARN] No reports found to email."
        } else {
            // Step 4: Create email with attachments
            emailext(
                subject: subject,
                body: body,
                from: EMAIL_FROM,
                to: EMAIL_TO,
                mimeType: 'text/html',
                attachmentsPattern: '**/reports/**/*.html, **/zap_reports/*.html, **/test-results/*.xml',
                replyTo: EMAIL_FROM,
                smtpHost: SMTP_SERVER,
                smtpPort: SMTP_PORT,
                charset: 'UTF-8',
                mimeCharset: 'UTF-8',
                smtpUsername: SMTP_USERNAME,
                smtpPassword: SMTP_PASSWORD,
                useSsl: true
            )

            echo "[INFO] Email with reports sent to ${EMAIL_TO}"
        }
    }
}

return [archiveAndEmailReports: archiveAndEmailReports]
