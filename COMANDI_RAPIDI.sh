#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════
#   COMANDI RAPIDI PER CARICARE LO STUDIO MELANOMA SU cBIOPORTAL
# ═══════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────
# 1. DALLA TUA MACCHINA LOCALE - Copia file sulla macchina cBioPortal
# ───────────────────────────────────────────────────────────────────────

scp -i ~/.ssh/id_ed25519.pub \
    -o ProxyJump=gbucci@bastion-sgsi.cnaf.infn.it \
    melanoma_study.tar.gz ubuntu@131.154.26.79:~/

# ───────────────────────────────────────────────────────────────────────
# 2. DALLA TUA MACCHINA LOCALE - Connettiti alla macchina
# ───────────────────────────────────────────────────────────────────────

ssh -i ~/.ssh/id_ed25519.pub \
    -J gbucci@bastion-sgsi.cnaf.infn.it \
    ubuntu@131.154.26.79

# ═══════════════════════════════════════════════════════════════════════
# DA QUI IN POI: COMANDI SULLA MACCHINA CBIOPORTAL (131.154.26.79)
# ═══════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────
# 3. Decomprimi lo studio
# ───────────────────────────────────────────────────────────────────────

cd ~
tar -xzf melanoma_study.tar.gz
ls -lh melanoma_study/

# ───────────────────────────────────────────────────────────────────────
# 4a. METODO AUTOMATICO (consigliato) - Usa lo script
# ───────────────────────────────────────────────────────────────────────

cd melanoma_study
chmod +x load_study_on_server.sh
./load_study_on_server.sh

# ───────────────────────────────────────────────────────────────────────
# 4b. METODO MANUALE - Comandi uno per uno
# ───────────────────────────────────────────────────────────────────────

# Verifica che il container sia attivo
sudo docker ps | grep cbioportal-container

# Copia lo studio nel container
sudo docker cp ~/melanoma_study cbioportal-container:/data/

# Verifica i file nel container
sudo docker exec cbioportal-container ls -lh /data/melanoma_study/

# Validazione (opzionale ma consigliata)
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    python3 validateData.py -s /data/melanoma_study -html /data/validation_report.html
"

# Scarica il report di validazione
sudo docker cp cbioportal-container:/data/validation_report.html /tmp/

# Caricamento in cBioPortal
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    ./metaImport.py -s /data/melanoma_study
"

# ───────────────────────────────────────────────────────────────────────
# 5. Riavvia il container per vedere lo studio
# ───────────────────────────────────────────────────────────────────────

sudo docker restart cbioportal-container

# Attendi circa 2 minuti
sleep 120

# Verifica che il container sia ripartito
sudo docker ps | grep cbioportal

# ───────────────────────────────────────────────────────────────────────
# 6. Verifica sul web
# ───────────────────────────────────────────────────────────────────────

echo "Vai su: http://131.154.26.79:9090"
echo "Cerca: 'Melanoma COLO-829' o 'COLO-829'"

# ═══════════════════════════════════════════════════════════════════════
#   COMANDI UTILI PER TROUBLESHOOTING
# ═══════════════════════════════════════════════════════════════════════

# Log del container cBioPortal
sudo docker logs -f cbioportal-container

# Log del database MySQL
sudo docker logs cbioportal-database-container

# Verifica studi nel database
sudo docker exec cbioportal-container bash -c "
    mysql -u cbio_user -pP@ssword1 cbioportal -e \
    'SELECT CANCER_STUDY_IDENTIFIER, NAME FROM cancer_study;'
"

# Verifica il nostro studio
sudo docker exec cbioportal-container bash -c "
    mysql -u cbio_user -pP@ssword1 cbioportal -e \
    'SELECT * FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER=\"melanoma_colo829_test\";'
"

# Conta mutazioni caricate
sudo docker exec cbioportal-container bash -c "
    mysql -u cbio_user -pP@ssword1 cbioportal -e \
    'SELECT COUNT(*) FROM mutation WHERE GENETIC_PROFILE_ID IN 
    (SELECT GENETIC_PROFILE_ID FROM genetic_profile WHERE CANCER_STUDY_ID = 
    (SELECT CANCER_STUDY_ID FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER=\"melanoma_colo829_test\"));'
"

# Rimuovi lo studio (se vuoi ricaricare)
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    ./cbioportalImporter.py -c remove-study -id melanoma_colo829_test
"

# Restart tutti i container
sudo docker restart cbioportal-container cbioportal-database-container cbioportal-session-container

# ═══════════════════════════════════════════════════════════════════════
#   INFO CONTAINER
# ═══════════════════════════════════════════════════════════════════════

# Lista tutti i container
sudo docker ps -a

# Stato containers
sudo docker ps

# Spazio disco
sudo docker exec cbioportal-container df -h

# Connessione MySQL diretta
sudo docker exec -it cbioportal-database-container \
    mysql -u cbio_user -pP@ssword1 cbioportal

