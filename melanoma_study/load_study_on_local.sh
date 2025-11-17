#!/bin/bash
# Script for loading melanoma study to LOCAL cBioPortal instance
# Adapted for local development/testing environments

set -e

# Configuration - adjust these for your environment
STUDY_DIR="${STUDY_DIR:-$HOME/melanoma_study}"
CONTAINER="${CONTAINER:-cbioportal-container}"
CBIOPORTAL_URL="${CBIOPORTAL_URL:-localhost:8080}"

echo "============================================"
echo "Loading Melanoma Study to Local cBioPortal"
echo "============================================"
echo
echo "Target: $CBIOPORTAL_URL"
echo

# Verify study directory exists
if [ ! -d "$STUDY_DIR" ]; then
    echo "❌ ERROR: Directory $STUDY_DIR not found!"
    echo "Please ensure the study is extracted to: $STUDY_DIR"
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

# Validate study
echo "[3/4] Validating study..."
echo "This may take a few seconds..."
sudo docker exec "$CONTAINER" bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    python3 validateData.py -s /data/melanoma_study -html /data/validation_report.html
"

VALIDATION_EXIT_CODE=$?

# Copy validation report
sudo docker cp "$CONTAINER:/data/validation_report.html" /tmp/validation_report.html 2>/dev/null || true

if [ $VALIDATION_EXIT_CODE -eq 0 ]; then
    echo "✓ Validation completed successfully"
    if [ -f /tmp/validation_report.html ]; then
        echo "  Validation report saved to: /tmp/validation_report.html"
    fi
else
    echo "⚠ Validation failed - check errors above"
    if [ -f /tmp/validation_report.html ]; then
        echo "  See detailed report: /tmp/validation_report.html"
    fi
    read -p "Continue with loading anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Loading cancelled."
        exit 1
    fi
fi
echo

# Load study to cBioPortal
echo "[4/4] Loading study to cBioPortal..."
echo "This may take several minutes..."
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
    echo "Restart container to see the study:"
    echo "  sudo docker restart $CONTAINER"
    echo
    echo "Once restarted (about 2 minutes), go to:"
    echo "  http://$CBIOPORTAL_URL"
    echo
    echo "Search for: 'Melanoma COLO-829'"
    echo
else
    echo "❌ Error during loading"
    echo "Check container logs:"
    echo "  sudo docker logs $CONTAINER"
    exit 1
fi
