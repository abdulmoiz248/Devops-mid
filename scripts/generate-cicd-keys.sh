#!/bin/bash
# Generate SSH Keys for CI/CD Pipeline
# This script creates SSH keys that will be used by GitHub Actions

set -e

echo "════════════════════════════════════════════════════════════"
echo "  SSH Key Generator for GitHub Actions CI/CD Pipeline"
echo "════════════════════════════════════════════════════════════"
echo ""

# Define key path
KEY_PATH="./cicd-keys/github-actions-key"
mkdir -p cicd-keys

# Generate SSH key pair
echo "📝 Generating SSH key pair..."
ssh-keygen -t rsa -b 4096 -f "$KEY_PATH" -N "" -C "github-actions-cicd"

echo ""
echo "✅ SSH keys generated successfully!"
echo ""
echo "════════════════════════════════════════════════════════════"
echo "  NEXT STEPS:"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "1️⃣  Add these secrets to your GitHub repository:"
echo "   (Settings → Secrets and variables → Actions → New secret)"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

# Display private key
echo "🔑 SSH_PRIVATE_KEY (copy entire output below):"
echo "------------------------------------------------------------"
cat "${KEY_PATH}"
echo "------------------------------------------------------------"
echo ""

# Display public key
echo "🔓 SSH_PUBLIC_KEY (copy entire output below):"
echo "------------------------------------------------------------"
cat "${KEY_PATH}.pub"
echo "------------------------------------------------------------"
echo ""

echo "════════════════════════════════════════════════════════════"
echo ""
echo "2️⃣  Copy the keys to GitHub Secrets:"
echo ""
echo "   For SSH_PRIVATE_KEY:"
if command -v pbcopy &> /dev/null; then
    cat "${KEY_PATH}" | pbcopy
    echo "   ✅ Private key copied to clipboard (macOS)"
elif command -v xclip &> /dev/null; then
    cat "${KEY_PATH}" | xclip -selection clipboard
    echo "   ✅ Private key copied to clipboard (Linux)"
else
    echo "   📋 Manually copy the private key above"
fi
echo ""
echo "   For SSH_PUBLIC_KEY:"
echo "   📋 Manually copy the public key above"
echo ""

echo "════════════════════════════════════════════════════════════"
echo ""
echo "⚠️  IMPORTANT SECURITY NOTES:"
echo ""
echo "   • Keys are stored in: cicd-keys/"
echo "   • This directory is in .gitignore"
echo "   • NEVER commit these keys to git"
echo "   • Keep the private key secure"
echo "   • Delete keys after adding to GitHub Secrets (optional)"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo "3️⃣  Test your setup:"
echo ""
echo "   cd infra"
echo "   terraform plan -var=\"ssh_public_key=\$(cat ../cicd-keys/github-actions-key.pub)\""
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""
echo "✨ Setup complete! Now add the secrets to GitHub and run the pipeline."
echo ""
