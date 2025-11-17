#!/bin/bash
# Script da eseguire SULLA MACCHINA CBIOPORTAL (131.154.26.79)
# Carica lo studio melanoma in cBioPortal

set -e

STUDY_DIR="/home/ubuntu/melanoma_study"
CONTAINER="cbioportal-container"

echo "============================================"
echo "Caricamento Studio Melanoma in cBioPortal"
echo "============================================"
echo

# Verifica che lo studio esista
if [ ! -d "$STUDY_DIR" ]; then
    echo "❌ ERRORE: Directory $STUDY_DIR non trovata!"
    echo "Assicurati di aver copiato lo studio sulla macchina."
    exit 1
fi

echo "✓ Studio trovato in $STUDY_DIR"
echo

# Verifica che il container sia running
if ! sudo docker ps | grep -q "$CONTAINER"; then
    echo "❌ ERRORE: Container $CONTAINER non è in esecuzione!"
    echo "Avvia il container prima di procedere."
    exit 1
fi

echo "✓ Container $CONTAINER è running"
echo

# Copia lo studio nel container
echo "[1/4] Copia studio nel container..."
sudo docker cp "$STUDY_DIR" "$CONTAINER:/data/"
if [ $? -eq 0 ]; then
    echo "✓ Studio copiato nel container"
else
    echo "❌ Errore nella copia"
    exit 1
fi
echo

# Verifica che i file siano nel container
echo "[2/4] Verifica presenza file nel container..."
sudo docker exec "$CONTAINER" ls -lh /data/melanoma_study/ || {
    echo "❌ File non trovati nel container"
    exit 1
}
echo "✓ File verificati"
echo

# Validazione dello studio
echo "[3/4] Validazione studio..."
echo "Questo può richiedere alcuni secondi..."
sudo docker exec "$CONTAINER" bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    python3 validateData.py -s /data/melanoma_study -html /data/validation_report.html
"

if [ $? -eq 0 ]; then
    echo "✓ Validazione completata con successo"
    
    # Copia il report di validazione
    sudo docker cp "$CONTAINER:/data/validation_report.html" /tmp/validation_report.html 2>/dev/null || true
    if [ -f /tmp/validation_report.html ]; then
        echo "  Report di validazione salvato in: /tmp/validation_report.html"
    fi
else
    echo "⚠ Validazione fallita - controlla gli errori"
    sudo docker cp "$CONTAINER:/data/validation_report.html" /tmp/validation_report.html 2>/dev/null || true
    echo "  Vedi report: /tmp/validation_report.html"
    read -p "Vuoi procedere comunque con il caricamento? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Caricamento annullato."
        exit 1
    fi
fi
echo

# Caricamento dello studio
echo "[4/4] Caricamento studio in cBioPortal..."
echo "Questo può richiedere alcuni minuti..."
sudo docker exec "$CONTAINER" bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    ./metaImport.py -s /data/melanoma_study
"

if [ $? -eq 0 ]; then
    echo "✓ Studio caricato con successo!"
    echo
    echo "============================================"
    echo "✓ COMPLETATO!"
    echo "============================================"
    echo
    echo "Il tuo studio è ora in cBioPortal."
    echo
    echo "Riavvia il container per vedere lo studio:"
    echo "  sudo docker restart $CONTAINER"
    echo
    echo "Una volta riavviato (circa 2 minuti), vai a:"
    echo "  http://131.154.26.79:9090"
    echo
    echo "E cerca: 'Melanoma COLO-829'"
    echo
else
    echo "❌ Errore durante il caricamento"
    echo "Controlla i log del container:"
    echo "  sudo docker logs $CONTAINER"
    exit 1
fi
