cat << 'EOF' > /opt/zimbra/backup/backup_account_zimbra_v2.sh
#!/bin/bash

# Pastikan script dijalankan sebagai user zimbra
if [ "$(whoami)" != "zimbra" ]; then
    echo "[!] Script ini harus dijalankan sebagai user 'zimbra'."
    echo "    Silakan jalankan: su - zimbra -c $0"
    exit 1
fi

# Variabel Utama
HOSTNAME_VAL=$(hostname -s)
TARGET_BASE="/opt/zimbra/backup"
DATE=$(date +%Y%m%d_%H%M%S)
FOLDER_NAME="zimbra_backup_v2_${HOSTNAME_VAL}_${DATE}"
BACKUP_DIR="$TARGET_BASE/$FOLDER_NAME"

# Buat direktori utama jika belum ada
mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR" || exit 1

echo "=================================================="
echo " Starting Zimbra Metadata & Mailbox Backup (V2)"
echo " Hostname      : $HOSTNAME_VAL"
echo " Target Folder : $BACKUP_DIR"
echo "=================================================="

# 1. Export Domain & Admin Accounts
echo -n "[1/9] Mengambil daftar Domain... "
zmprov gad > domains.txt
echo "Selesai."

echo -n "[2/9] Mengambil daftar Akun Admin... "
zmprov gaaa > admins.txt
echo "Selesai."

# 2. Export Email List & Hitung Jumlah
echo -n "[3/9] Mengambil seluruh daftar Akun Email... "
zmprov -l gaa > emails.txt
TOTAL_EMAILS=$(wc -l < emails.txt)
echo "Selesai. Total Akun: $TOTAL_EMAILS"

# 3. Export Distribution Lists
echo -n "[4/9] Mengambil daftar Distribution List (DL)... "
zmprov gadl > distributinlist.txt
TOTAL_DL=$(wc -l < distributinlist.txt)
echo "Selesai. Total DL: $TOTAL_DL"

mkdir -p distributinlist_members

if [ "$TOTAL_DL" -gt 0 ]; then
    echo "      --> Memproses anggota Distribution List..."
    COUNTER=0
    while read -r dl; do
        [ -z "$dl" ] && continue
        COUNTER=$((COUNTER + 1))
        echo "          [$COUNTER/$TOTAL_DL] Memproses DL: $dl (mohon tunggu...)"
        zmprov gdlm "$dl" > "distributinlist_members/$dl.txt"
    done < distributinlist.txt
fi

# Prepare Directory untuk data per user & mailbox
mkdir -p userpass forwarding userdata mailbox

# 4. Loop Utama untuk Metadata User (Password Hash, Forwarding, User Data)
echo "[5/9] Memproses Password Hash, Forwarding, dan User Data..."

CURRENT=0
while read -r email; do
    [ -z "$email" ] && continue
    CURRENT=$((CURRENT + 1))
    
    # Counter progres dinamis di baris yang sama (\r)
    echo -ne "      --> [$CURRENT/$TOTAL_EMAILS] Memproses metadata: $email ...\r"

    # Backup Password Hash
    zmprov -l ga "$email" userPassword | grep userPassword: | awk '{print $2}' > "userpass/$email.shadow"

    # Backup Forwarding Address
    zmprov -l ga "$email" zimbraPrefMailForwardingAddress | grep zimbraPrefMailForwardingAddress: | awk '{print $2}' > "forwarding/$email.forward"

    # Backup User Data Metadata
    zmprov ga "$email" | grep -i "Name:" > "userdata/$email.txt"

done < emails.txt

echo -e "\n[6/9] Selesai memproses seluruh metadata akun."

# 5. Backup Mailbox (.tgz) Per Account
echo "[7/9] Memproses Export Mailbox (.tgz)..."
echo "      PROSES INI MEMAKAN WAKTU LAMA DAN UKURAN DISK BESAR. MOHON TUNGGU..."

CURRENT_MBX=0
while read -r email; do
    [ -z "$email" ] && continue
    CURRENT_MBX=$((CURRENT_MBX + 1))
    
    echo "      --> [$CURRENT_MBX/$TOTAL_EMAILS] Exporting Mailbox: $email ..."
    
    # Eksekusi zmmailbox getRestURL
    zmmailbox -z -m "$email" getRestURL '/?fmt=tgz' > "mailbox/$email.tgz" 2> "mailbox/$email.err"
    
    # Jika file error kosong, hapus file .err
    if [ ! -s "mailbox/$email.err" ]; then
        rm -f "mailbox/$email.err"
    fi

done < emails.txt

echo "[7/9] Selesai memproses export seluruh mailbox."

# 6. Cleanup file kosong pada folder forwarding
echo -n "[8/9] Membersihkan file forwarding kosong... "
find forwarding/ -type f -empty -delete
echo "Selesai."

# 7. Kompresi Folder Utama ke .tar.gz
echo -n "[9/9] Mengompresi seluruh direktori backup ke .tar.gz... "
cd "$TARGET_BASE" || exit 1
tar -czf "${FOLDER_NAME}.tar.gz" "$FOLDER_NAME"

# Hapus folder mentah setelah berhasil dikompresi
if [ -f "${FOLDER_NAME}.tar.gz" ]; then
    rm -rf "$FOLDER_NAME"
    echo "Selesai."
else
    echo "Gagal membuat file kompresi!"
    exit 1
fi

echo "=================================================="
echo " Backup V2 Selesai!"
echo " File Hasil Backup: $TARGET_BASE/${FOLDER_NAME}.tar.gz"
echo "=================================================="
EOF
