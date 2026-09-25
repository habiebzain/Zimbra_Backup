# Zimbra Backup Automation Scripts (V1 & V2)

Automated Bash scripts for exporting and archiving Zimbra Mail Server account metadata, distribution lists, user configurations, and full mailbox data into compressed `.tar.gz` archives with dynamic progress tracking.

## 📋 Features

* **Progress Indicators**: Real-time CLI output (`[X/Y] Processing account...`) so system administrators can track execution status without guessing.

* **Hostname & Date Stamping**: Backup archives are automatically named using the server hostname and timestamp (`zimbra_backup_[HOSTNAME]_[DATE].tar.gz`).

* **Safe Reading Loops**: Uses robust `while read -r` loops instead of fragile `for i in $(cat ...)` to handle accounts with special characters safely.

* **Automatic Storage Optimization**: Cleans up empty forwarding files and removes uncompressed raw directories after creating the final `.tar.gz` package.

* **Error Capturing (V2)**: Captures individual mailbox export errors (`.err` files) without interrupting the overall backup sequence.

## 🚀 Script Overview

| **Script Version** | **Description** | **Target Outputs** | 
| **`backup_account_zimbra.sh` (V1)** | Fast metadata-only backup. | Domains, Admin lists, Emails list, Distribution Lists + members, Password hashes (`.shadow`), Forwarding addresses (`.forward`), and User attributes. | 
| **`backup_account_zimbra_v2.sh` (V2)** | Full backup (Metadata + Mailbox content). | All metadata from V1 **PLUS** complete mailbox dumps (`.tgz`) for every account via `zmmailbox REST API`. | 

## 🛠️ Prerequisites & Requirements

* **Operating System**: Linux running Zimbra Collaboration Suite (ZCS).

* **User Permissions**: Must be executed by the `zimbra` user.

* **Default Output Path**: `/opt/zimbra/backup/` (Ensure sufficient disk space is available, especially for V2).

## 📥 Installation & Setup

1. **Clone or download this repository** to your server:

   ```
   cd /opt/zimbra/backup
   # Download or create the script files here
   
   ```

2. **Make the scripts executable**:

   ```
   chmod +x backup_account_zimbra.sh
   chmod +x backup_account_zimbra_v2.sh
   
   ```

3. **Convert Windows line endings (optional, if copied from Windows)**:

   ```
   sed -i 's/\r$//' backup_account_zimbra.sh
   sed -i 's/\r$//' backup_account_zimbra_v2.sh
   
   ```

## ⚙️ Usage

Switch to the `zimbra` user before running either script:

```
su - zimbra

```

### Option A: Run V1 (Metadata Backup)

Ideal for quick configuration snapshots and lightweight daily metadata backups.

```
/opt/zimbra/backup/backup_account_zimbra.sh

```

### Option B: Run V2 (Full Metadata + Mailbox Backup)

Ideal for full system backups or disaster recovery preparedness.

```
/opt/zimbra/backup/backup_account_zimbra_v2.sh

```

## 📂 Backup File Structure (Inside `.tar.gz`)

Once uncompressed, the backup folder contains the following structure:

```
zimbra_backup_[HOSTNAME]_[TIMESTAMP]/
├── domains.txt                   # All domain names
├── admins.txt                    # List of admin accounts
├── emails.txt                    # List of all user mailboxes
├── distributinlist.txt           # List of distribution lists
├── distributinlist_members/      # Folder containing members for each DL
│   └── example-dl@domain.com.txt
├── userpass/                     # Exported user password hashes
│   └── user@domain.com.shadow
├── forwarding/                   # Active mail forwarding settings
│   └── user@domain.com.forward
├── userdata/                     # Account metadata attributes
│   └── user@domain.com.txt
└── mailbox/                      # (V2 Only) Full mailbox archives
    ├── user1@domain.com.tgz
    └── user2@domain.com.tgz

```

## ⏰ Automating with Cron

To set up a scheduled backup job, open the `zimbra` user crontab:

```
crontab -e -u zimbra

```

Add a schedule (e.g., Run V1 daily at 1:00 AM, and V2 every Sunday at 2:00 AM):

```
# Daily Metadata Backup (V1) at 01:00 AM
0 1 * * * /opt/zimbra/backup/backup_account_zimbra.sh > /dev/null 2>&1

# Weekly Full Mailbox Backup (V2) every Sunday at 02:00 AM
0 2 * * 0 /opt/zimbra/backup/backup_account_zimbra_v2.sh > /dev/null 2>&1

```

## 📝 License

This project is open-source and free to use under the [MIT License](LICENSE).
