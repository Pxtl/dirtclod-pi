#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
DEST_HOST="$1"
if [ -z "$DEST_HOST" ]; then
    echo "Usage: $0 <destination-host>"
    exit 1
fi

MITM_DIR="$ROOT_DIR/volumes/ro/ssh-mitm-ssh"
PI_DIR="$ROOT_DIR/volumes/ro/ssh-pi-agent"

echo "1. Build authorized_keys from all agent public keys..."
echo "  a. Start fresh"
mkdir -p $MITM_DIR
: > "$MITM_DIR/authorized_keys"

echo "  b. Append each .pub file"
for pub in "$PI_DIR"/*.pub; do
    [ -e "$pub" ] || continue
    cat "$pub" >> "$MITM_DIR/authorized_keys"
done

for pub in "$MITM_DIR"/*.pub; do
    [ -e "$pub" ] || continue
    cat "$pub" >> "$MITM_DIR/authorized_keys"
done

echo "2. Write SSH config for MITM..."
cat > "$MITM_DIR/config" <<EOF
Host dest
    HostName $DEST_HOST
    User git
    IdentityFile /home/git/.ssh/id_ed25519
    UserKnownHostsFile /home/git/.ssh/known_hosts
    StrictHostKeyChecking yes
EOF
echo "ssh-mitm ssh config generated for $DEST_HOST"

echo "3. Write SSH config for pi-agent..."
mkdir -p $PI_DIR
cat > "$PI_DIR/config" <<EOF
Host $DEST_HOST
    HostName ssh-mitm
    Port 22
    User root
    IdentityFile ~/.ssh/id_ed25519
EOF
echo "pi-agent ssh config generated for $DEST_HOST"

# echo "4. Write known_hosts for ssh-mitm..."
# FIXME: github is strict about not abusing this, you will get rate-limited.
# ssh-keyscan $DEST_HOST > "$ROOT_DIR/volumes/ro/ssh-mitm/known_hosts"
echo "$DEST_HOST keyscanned for ssh-mitm/known_hosts"
echo "Done '${BASH_SOURCE[0]}'."