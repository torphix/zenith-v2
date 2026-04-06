#!/usr/bin/env bash
# Deploy Firestore and Storage security rules to Firebase.
# Usage: ./deploy-rules.sh

set -euo pipefail

echo "Deploying Firestore rules..."
firebase deploy --only firestore:rules

echo "Deploying Storage rules..."
firebase deploy --only storage

echo "Done. Rules deployed successfully."
