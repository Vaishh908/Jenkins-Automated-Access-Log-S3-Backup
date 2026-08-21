# Automated Jenkins Job Triggered by Access Log Size 

# Project Overview

This project implements an automated Apache access log monitoring and backup system using Linux Shell Script, Jenkins, Amazon S3, AWS IAM Role, and Email Notification.

The system continuously monitors the Apache access log file. When the log size reaches a configured threshold, a shell script triggers a Jenkins pipeline. Jenkins then:

- Checks AWS authentication.
- Copies the Apache access log.
- Creates a timestamped backup.
- Uploads the backup to Amazon S3.
- Clears the original Apache log file.
- Sends an email notification.

The solution uses an IAM Role attached to the Jenkins EC2 instance, so no long-lived AWS access keys are stored in the Jenkins configuration or shell script.

---

# Architectural Diagram


---

# Technology Used

| Technology             | Purpose                              |
| ---------------------- | ------------------------------------ |
| Ubuntu Linux           | Server operating system              |
| Apache2                | Web server and access log generation |
| Bash                   | Log monitoring automation            |
| Jenkins                | CI/CD pipeline automation            |
| AWS EC2                | Jenkins server                       |
| AWS IAM                | Secure AWS authentication            |
| Amazon S3              | Log backup storage                   |
| AWS CLI                | S3 interaction                       |
| Email Extension Plugin | Jenkins email notification           |
| Cron                   | Periodic log-size monitoring         |

---

# Prerequisites

Before implementing the project, install or configure:

             Ubuntu EC2 instance
             Apache2
             Jenkins
             AWS CLI
             AWS IAM Role
             Amazon S3 bucket
            Jenkins Email Extension Plugin
            Internet connectivity

Verify Apache:

            sudo systemctl status apache2

Verify AWS CLI:

            aws --version

Verify Jenkins:

         sudo systemctl status jenkins

---

# Step 1 — Install Apache

Update the Ubuntu package repository:

sudo apt update

Install Apache:

sudo apt install apache2 -y

Start Apache:

sudo systemctl start apache2

Enable Apache at boot:

sudo systemctl enable apache2

Check the status:

sudo systemctl status apache2

The Apache access log is located at:

/var/log/apache2/access.log

Verify:

ls -lh /var/log/apache2/access.log

---

## Step 2 — Generate Apache Access Logs

Access the Apache server from a browser:

http://<EC2-PUBLIC-IP>

Each request generates an entry in:

/var/log/apache2/access.log

Check the log:

sudo tail -20 /var/log/apache2/access.log

---

## Step 3 — Create the S3 Bucket

Create an S3 bucket in:

US East (N. Virginia)
us-east-1

Example bucket:

jenkins-access-log-backup-2026-vaishnavi

Create the backup prefix:

access-logs/

The final S3 path is:

s3://jenkins-access-log-backup-2026-vaishnavi/access-logs/

---

## Step 4 — Create IAM Role for Jenkins

Create an IAM role:

Jenkins-S3-Log-Upload-Role

Attach the required S3 permissions.

Attach this IAM role to the EC2 instance running Jenkins.

Verify the role from the server:

aws sts get-caller-identity

Expected output:

{
    "Account": "170415412411",
    "Arn": "arn:aws:sts::170415412411:assumed-role/Jenkins-S3-Log-Upload-Role/..."
}

This confirms that Jenkins is using the EC2 IAM role.

---

## Step 5 — Configure AWS Region

Configure the AWS CLI region:

sudo -u jenkins aws configure set region us-east-1

Verify:

sudo -u jenkins aws configure get region

Expected:

us-east-1

---

## Step 6 — Test S3 Access

Test access to the bucket:

sudo -u jenkins aws s3 ls \
s3://jenkins-access-log-backup-2026-vaishnavi

Expected:

PRE access-logs/

Test uploading a file:

echo "Jenkins S3 test" > /tmp/test.txt

Then:

sudo -u jenkins aws s3 cp /tmp/test.txt \
s3://jenkins-access-log-backup-2026-vaishnavi/access-logs/ \
--region us-east-1

---

## Step 7 — Create Log Monitoring Script

Create:

nano ~/monitor_apache_log.sh

Add:

#!/bin/bash


# ==========================================================
# Apache Log Size Monitoring Script
# ==========================================================


LOG_FILE="/var/log/apache2/access.log"
THRESHOLD_MB=5


JENKINS_URL="http://localhost:8080"
JENKINS_JOB="Access-Log-S3-Backup"


echo "=========================================="
echo "Apache Log Monitoring Started"
echo "=========================================="


if [ ! -f "$LOG_FILE" ]; then
    echo "ERROR: Log file not found: $LOG_FILE"
    exit 1
fi


LOG_SIZE_MB=$(du -m "$LOG_FILE" | cut -f1)


echo "Log file : $LOG_FILE"
echo "Log size : ${LOG_SIZE_MB} MB"
echo "Threshold: ${THRESHOLD_MB} MB"


if [ "$LOG_SIZE_MB" -ge "$THRESHOLD_MB" ]; then


    echo "WARNING: Log size exceeded threshold."
    echo "Triggering Jenkins job..."


    curl -X POST \
        "${JENKINS_URL}/job/${JENKINS_JOB}/build"


    if [ $? -eq 0 ]; then
        echo "Jenkins job triggered successfully."
    else
        echo "ERROR: Failed to trigger Jenkins job."
        exit 1
    fi


else


    echo "Log size is below threshold."
    echo "No Jenkins job triggered."


fi


echo "=========================================="

Make the script executable:

chmod +x ~/monitor_apache_log.sh

Test:

~/monitor_apache_log.sh
Step 8 — Configure Jenkins Job

Create a Pipeline job named:

Access-Log-S3-Backup

Go to:

Jenkins
→ New Item
→ Pipeline
→ Access-Log-S3-Backup

Select:

Pipeline script

Use the following Pipeline.

pipeline {
                    --recursive \
                    --region us-east-1


                    echo "Access log uploaded successfully."
                '''
            }
        }


        stage('Clear Log File') {
            steps {
                sh '''
                    echo "Clearing Apache access log..."


                    sudo truncate -s 0 /var/log/apache2/access.log


                    echo "Log file cleared."


                    ls -lh /var/log/apache2/access.log
                '''
            }
        }


        stage('Send Email') {
            steps {
                emailext(
                    subject: "Jenkins S3 Access Log Backup - SUCCESS",
                    body: """
Hello,


Apache access log backup completed successfully.


Jenkins Job:
${env.JOB_NAME}


Build:
#${env.BUILD_NUMBER}


S3 Bucket:
jenkins-access-log-backup-2026-vaishnavi


S3 Location:
s3://jenkins-access-log-backup-2026-vaishnavi/access-logs/


Status:
SUCCESS


The Apache access log was backed up and cleared successfully.


Regards,
Jenkins
""",
                    to: "vaishuj500@gmail.com"
                )
            }
        }
    }


    post {
        failure {
            emailext(
                subject: "Jenkins S3 Access Log Backup - FAILED",
                body: """
Apache access log backup failed.


Job: ${env.JOB_NAME}
Build: #${env.BUILD_NUMBER}


Please check Jenkins Console Output.
""",
                to: "vaishuj500@gmail.com"
            )
        }
    }
}
Step 9 — Configure Jenkins Sudo Permission

Jenkins needs permission to clear the Apache log.

Run:

sudo visudo

Add:

jenkins ALL=(root) NOPASSWD: /usr/bin/truncate

Save the file.

Test:

sudo -u jenkins sudo truncate -s 0 /var/log/apache2/access.log

Verify:

ls -lh /var/log/apache2/access.log

---

## Step 10 — Configure Email Notification

Install the:

Email Extension Plugin

Jenkins plugin used:

Email Extension Plugin

Configure SMTP under:

Manage Jenkins
→ System
→ Extended E-mail Notification

For Gmail, configure SMTP using:

SMTP Server: smtp.gmail.com
SMTP Port: 587
Use TLS: Enabled
SMTP Authentication: Enabled

Use a Gmail App Password rather than the normal Gmail account password.

Test using:

Test configuration by sending test e-mail

A successful test should result in an email such as:

This is test email #1 sent from Jenkins
Step 11 — Configure Automatic Monitoring

Edit the cron table:

crontab -e

Add:

*/5 * * * * /home/ubuntu/monitor_apache_log.sh >> /home/ubuntu/apache-monitor.log 2>&1

This executes the monitoring script every five minutes.

Check the monitoring log:

cat ~/apache-monitor.log

Example:

==========================================
Apache Log Monitoring Started
==========================================
Log file : /var/log/apache2/access.log
Log size : 1 MB
Threshold: 5 MB
Log size is below threshold.
No Jenkins job triggered.
==========================================
Step 12 — Test Automatic Trigger

For testing, temporarily set:

THRESHOLD_MB=0

Run:

~/monitor_apache_log.sh

The script should detect that the threshold is exceeded and trigger:

Access-Log-S3-Backup

After testing, restore:

THRESHOLD_MB=5
Step 13 — Verify Jenkins Build

Open:

Access-Log-S3-Backup

The Jenkins console should show:

[Pipeline] Start of Pipeline


Checking AWS access...


AWS access verified.


Starting Apache access log backup...


Apache access log copied successfully.


Uploading access log to S3...


Access log uploaded successfully.


Clearing Apache access log...


Log file cleared.


Sending email to: vaishuj500@gmail.com


Finished: SUCCESS
Step 14 — Verify S3 Upload

Run:

aws s3 ls \
s3://jenkins-access-log-backup-2026-vaishnavi/access-logs/ \
--region us-east-1

Example:

2026-08-21 08:01:09       4900 access_20260821_080109.log

This confirms that the log has been successfully backed up to S3.

Step 15 — Verify Cleared Log

Check the Apache log:

ls -lh /var/log/apache2/access.log

Expected:

-rw-r----- 1 root adm 0 ... access.log

Or:

sudo du -h /var/log/apache2/access.log

Expected:

0 /var/log/apache2/access.log

The file is cleared but not deleted.

Step 16 — Email Verification

After a successful Jenkins build, the configured recipient receives:

To: vaishuj500@gmail.com


Subject:
Jenkins S3 Access Log Backup - SUCCESS

The email confirms:

Apache access log backup completed successfully.


S3 Bucket:
jenkins-access-log-backup-2026-vaishnavi


S3 Location:
s3://jenkins-access-log-backup-2026-vaishnavi/access-logs/


Status:
SUCCESS

Successful Implementation Evidence

The project was successfully tested using Jenkins Build #10.

The successful build demonstrated:

AWS authentication             SUCCESS
AWS region configuration       SUCCESS
Apache access log collection   SUCCESS
Timestamped backup             SUCCESS
S3 upload                      SUCCESS
Email notification             SUCCESS
Jenkins pipeline               SUCCESS

Example successful S3 upload:

upload: backup/access_20260821_080109.log
to s3://jenkins-access-log-backup-2026-vaishnavi/access-logs/access_20260821_080109.log

Jenkins result:

Finished: SUCCESS

# Project Structure

automated-log-backup/
│
├── README.md
│
├── scripts/
│   └── monitor_apache_log.sh
│
├── jenkins/
│   └── Jenkinsfile
│
└── screenshots/
    ├── apache-log.png
    ├── monitoring-script.png
    ├── jenkins-success.png
    ├── s3-upload.png
    ├── cleared-log.png
    └── email-success.png

---

# Result

The automated log backup system successfully monitors the Apache access log and integrates Linux shell scripting with Jenkins and AWS services. When the configured log-size threshold is reached, the monitoring script triggers the Jenkins pipeline. Jenkins authenticates to AWS using an IAM role, creates a timestamped copy of the Apache access log, uploads it to Amazon S3, clears the original log, and sends an email notification.

The successful Jenkins Build #10 demonstrated that the AWS authentication, log backup, S3 upload, and email notification stages were functioning correctly.

---

# Conclusion

The project provides an automated and secure approach for managing Apache access logs. By combining Bash scripting, Jenkins Pipeline automation, Amazon S3, IAM roles, and email notifications, manual log backup operations are eliminated. The solution provides reliable log storage, controlled AWS permissions, automated log cleanup, and notification of successful or failed backup operations. This implementation demonstrates practical knowledge of Linux administration, Shell scripting, Jenkins CI/CD, AWS IAM, Amazon S3, automation, and DevOps practices.

