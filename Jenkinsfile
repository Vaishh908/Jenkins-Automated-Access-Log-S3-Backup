pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        S3_BUCKET = 'jenkins-access-log-backup-2026-vaishnavi'
        S3_PATH = 'access-logs'
    }

    stages {

        stage('Check AWS Access') {
            steps {
                sh '''
                    echo "Checking AWS access..."

                    aws sts get-caller-identity

                    aws configure set region ${AWS_REGION}

                    echo "AWS region: ${AWS_REGION}"
                    echo "AWS access verified."
                '''
            }
        }

        stage('Backup Access Logs') {
            steps {
                sh '''
                    echo "Starting Apache access log backup..."

                    mkdir -p backup

                    TIMESTAMP=$(date +%Y%m%d_%H%M%S)

                    cp /var/log/apache2/access.log \
                       backup/access_${TIMESTAMP}.log

                    echo "Apache access log copied successfully."

                    ls -lh backup/
                '''
            }
        }

        stage('Upload to S3') {
            steps {
                sh '''
                    echo "Uploading access log to S3..."

                    aws s3 cp backup/ \
                    s3://${S3_BUCKET}/${S3_PATH}/ \
                    --recursive \
                    --region ${AWS_REGION}

                    echo "Access log uploaded successfully."
                '''
            }
        }

        stage('Send Email') {
            steps {
                emailext(
                    subject: "Jenkins - Apache Access Log Backup SUCCESS - Build #${BUILD_NUMBER}",
                    to: "vaishuj500@gmail.com",
                    body: """
Hello,

The Apache access log backup completed successfully.

Jenkins Job: ${JOB_NAME}
Build Number: ${BUILD_NUMBER}
AWS Region: ${AWS_REGION}
S3 Bucket: ${S3_BUCKET}
S3 Path: ${S3_PATH}

The Apache access log was copied and uploaded to Amazon S3 successfully.

Jenkins URL:
${BUILD_URL}

Regards,
Jenkins
"""
                )
            }
        }
    }

    post {
        failure {
            emailext(
                subject: "Jenkins - Apache Access Log Backup FAILED - Build #${BUILD_NUMBER}",
                to: "vaishuj500@gmail.com",
                body: """
Hello,

The Apache access log backup job failed.

Jenkins Job: ${JOB_NAME}
Build Number: ${BUILD_NUMBER}

Please check the Jenkins console output:

${BUILD_URL}console

Regards,
Jenkins
"""
            )
        }

        success {
            echo "========================================="
            echo "Apache access log backup completed."
            echo "S3 upload completed successfully."
            echo "========================================="
        }
    }
}
