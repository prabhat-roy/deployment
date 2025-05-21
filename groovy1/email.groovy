// email.groovy
def archiveAndEmailReports() {
    // Step 1: Archive reports
    echo "📁 Archiving reports..."
    archiveArtifacts artifacts: '**/*.txt, **/*.json, **/*.sarif', allowEmptyArchive: false

    // Step 2: Get email credentials and SMTP details from Jenkins credentials store
    withCredentials([
        usernamePassword(credentialsId: 'smtp-credentials', usernameVariable: 'SMTP_USER', passwordVariable: 'SMTP_PASS'),
        string(credentialsId: 'smtp-host', variable: 'SMTP_HOST'),
        string(credentialsId: 'smtp-port', variable: 'SMTP_PORT'),
        string(credentialsId: 'email-to', variable: 'EMAIL_TO'),
        string(credentialsId: 'email-from', variable: 'EMAIL_FROM')
    ]) {
        def smtpHost = env.SMTP_HOST  // Retrieved SMTP host from Jenkins credentials
        def smtpPort = env.SMTP_PORT  // Retrieved SMTP port from Jenkins credentials
        def smtpUser = env.SMTP_USER  // Retrieved SMTP username from Jenkins credentials
        def smtpPass = env.SMTP_PASS  // Retrieved SMTP password from Jenkins credentials
        def emailTo = env.EMAIL_TO    // Retrieved recipient email from Jenkins credentials
        def emailFrom = env.EMAIL_FROM // Retrieved sender email from Jenkins credentials
        def emailSubject = "CI Build Report for Build #${env.BUILD_NUMBER}"
        def emailBody = "Please find the attached reports from the latest CI build #${env.BUILD_NUMBER}. See attached reports for detailed results."

        // Step 3: Prepare email content
        def attachments = findFiles(glob: '**/*.txt, **/*.json, **/*.sarif')  // Include all relevant file types
        def attachmentPaths = attachments.collect { it.getPath() }

        // Step 4: Send email using the Email extension plugin
        emailext(
            to: emailTo,
            from: emailFrom,
            subject: emailSubject,
            body: emailBody,
            attachmentsPattern: attachmentPaths.join(', '),  // Attach all relevant files
            mimeType: 'text/html',
            smtpHost: smtpHost,
            smtpPort: smtpPort.toInteger(),
            smtpUsername: smtpUser,
            smtpPassword: smtpPass,
            attachFiles: true
        )

        echo "✅ Email sent with attached reports."
    }
}
