#!/bin/bash
################################################################################
# Fix GROUPS Field for melanoma_colo829_test Study
#
# This script updates the GROUPS field in the cancer_study table to make the
# study visible in the cBioPortal web interface.
#
# Run this on the remote cBioPortal server: ubuntu@131.154.26.79
################################################################################

set -e

echo "=========================================="
echo "Fixing GROUPS field for melanoma_colo829_test"
echo "=========================================="
echo ""

# Step 1: Update GROUPS field (using backticks to escape reserved keyword)
echo "Step 1: Updating GROUPS field to 'PUBLIC'..."
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "
UPDATE cancer_study
SET \`GROUPS\` = 'PUBLIC'
WHERE CANCER_STUDY_IDENTIFIER = 'melanoma_colo829_test';
"

if [ $? -eq 0 ]; then
    echo "✓ GROUPS field updated successfully"
else
    echo "✗ Failed to update GROUPS field"
    exit 1
fi

echo ""

# Step 2: Verify the update
echo "Step 2: Verifying the update..."
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "
SELECT CANCER_STUDY_IDENTIFIER, NAME, \`GROUPS\`, PUBLIC, STATUS
FROM cancer_study
WHERE CANCER_STUDY_IDENTIFIER = 'melanoma_colo829_test';
"

echo ""

# Step 3: Restart cBioPortal container
echo "Step 3: Restarting cBioPortal container to refresh cache..."
sudo docker restart cbioportal-container

if [ $? -eq 0 ]; then
    echo "✓ Container restarted successfully"
else
    echo "✗ Failed to restart container"
    exit 1
fi

echo ""
echo "Waiting for cBioPortal to start (approximately 2 minutes)..."
sleep 120

echo ""
echo "=========================================="
echo "Fix completed!"
echo "=========================================="
echo ""
echo "Now check the web interface at: http://131.154.26.79:9090"
echo ""
echo "The melanoma_colo829_test study should now be visible."
echo "Search for 'Melanoma COLO-829' in the portal."
echo ""
