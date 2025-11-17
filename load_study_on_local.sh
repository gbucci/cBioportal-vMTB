#!/bin/bash
# Script to load melanoma study on LOCAL cBioPortal machine (172.21.91.6)
# Adapted for cBioPortal version 4.1.13 running on port 8080

set -e

STUDY_DIR="/home/gbucci/melanoma_study"
CONTAINER="cbioportal-container"

echo "============================================"
echo "Loading Melanoma Study to Local cBioPortal"
echo "============================================"
echo
echo "Target: 172.21.91.6:8080 (cBioPortal 4.1.13)"
echo

# Verify study directory exists
if [ ! -d "$STUDY_DIR" ]; then
    echo "❌ ERROR: Directory $STUDY_DIR not found!"
    echo "Make sure you have extracted the study on this machine."
    exit 1
fi

echo "✓ Study found at $STUDY_DIR"
echo

# Verify container is running
if ! sudo docker ps | grep -q "$CONTAINER"; then
    echo "❌ ERROR: Container $CONTAINER is not running!"
    echo "Start the container before proceeding."
    exit 1
fi

echo "✓ Container $CONTAINER is running"
echo

# Copy study to container
echo "[1/4] Copying study to container..."
sudo docker cp "$STUDY_DIR" "$CONTAINER:/data/"
if [ $? -eq 0 ]; then
    echo "✓ Study copied to container"
else
    echo "❌ Copy failed"
    exit 1
fi
echo

# Verify files in container
echo "[2/4] Verifying files in container..."
sudo docker exec "$CONTAINER" ls -lh /data/melanoma_study/ || {
    echo "❌ Files not found in container"
    exit 1
}
echo "✓ Files verified"
echo

# Study validation
echo "[3/4] Validating study..."
echo "This may take a few seconds..."
sudo docker exec "$CONTAINER" bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    python3 validateData.py -s /data/melanoma_study -html /data/validation_report.html
"

if [ $? -eq 0 ]; then
    echo "✓ Validation completed successfully"

    # Copy validation report
    sudo docker cp "$CONTAINER:/data/validation_report.html" /tmp/validation_report.html 2>/dev/null || true
    if [ -f /tmp/validation_report.html ]; then
        echo "  Validation report saved to: /tmp/validation_report.html"
    fi
else
    echo "⚠ Validation failed - check errors"
    sudo docker cp "$CONTAINER:/data/validation_report.html" /tmp/validation_report.html 2>/dev/null || true
    echo "  See report: /tmp/validation_report.html"
    read -p "Do you want to proceed anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Loading cancelled."
        exit 1
    fi
fi
echo

# Load study
echo "[4/4] Loading study to cBioPortal..."
echo "This may take a few minutes..."
sudo docker exec "$CONTAINER" bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    ./metaImport.py -s /data/melanoma_study
"

if [ $? -eq 0 ]; then
    echo "✓ Study loaded successfully!"
    echo
    echo "============================================"
    echo "✓ COMPLETED!"
    echo "============================================"
    echo
    echo "Your study is now in cBioPortal."
    echo
    echo "Restart the container to see the study:"
    echo "  sudo docker restart $CONTAINER"
    echo
    echo "Once restarted (about 2 minutes), go to:"
    echo "  http://172.21.91.6:8080"
    echo
    echo "And search for: 'Melanoma COLO-829'"
    echo
else
    echo "❌ Error during loading"
    echo "Check container logs:"
    echo "  sudo docker logs $CONTAINER"
    exit 1
fi
