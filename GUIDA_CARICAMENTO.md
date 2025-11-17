# Guida: Caricamento Studio Melanoma COLO-829 su cBioPortal

## Contenuto Preparato

Ho preparato uno studio completo per cBioPortal con:

### Dati dello Studio
- **ID Studio**: `melanoma_colo829_test`
- **Nome**: Melanoma COLO-829 Test Case
- **Paziente**: C_UFLEBTVLHO (maschio, 45 anni, diagnosi 2022)
- **Campioni**: 
  - COLO-829 (tumore metastatico, Stage IV)
  - COLO-829BL (sangue normale)
- **Mutazioni**: 36 mutazioni somatiche inclusa BRAF V600E
- **Genoma di riferimento**: GRCh38/hg38

### Struttura File
```
melanoma_study/
├── meta_study.txt                      # Metadati studio
├── meta_cancer_type.txt               # Metadati tipo cancro
├── cancer_type.txt                    # Definizione melanoma
├── meta_clinical_patient.txt          # Metadati clinici paziente
├── data_clinical_patient.txt          # Dati clinici paziente
├── meta_clinical_sample.txt           # Metadati clinici campioni
├── data_clinical_sample.txt           # Dati clinici campioni
├── meta_mutations_extended.txt        # Metadati mutazioni
├── data_mutations_extended.maf        # File MAF con le mutazioni
├── case_lists/                        # Liste di campioni
│   ├── melanoma_colo829_test_all.txt
│   └── melanoma_colo829_test_sequenced.txt
├── load_study_on_server.sh           # Script di caricamento
└── README.md                          # Documentazione
```

## Procedura di Caricamento

### Opzione 1: Metodo Automatico (Consigliato)

#### 1. Trasferisci i file sulla macchina cBioPortal

Dalla tua **macchina locale**:

```bash
# Scarica l'archivio dal link che ti fornisco
# Poi copialo sulla macchina cBioPortal tramite bastion:

scp -i ~/.ssh/id_ed25519.pub \
    -o ProxyJump=gbucci@bastion-sgsi.cnaf.infn.it \
    melanoma_study.tar.gz ubuntu@131.154.26.79:~/
```

Ti verrà chiesto:
1. First Factor: password INFN
2. Second Factor: codice OTP

#### 2. Connettiti alla macchina cBioPortal

```bash
ssh -i ~/.ssh/id_ed25519.pub \
    -J gbucci@bastion-sgsi.cnaf.infn.it \
    -l ubuntu 131.154.26.79
```

#### 3. Decomprimi e carica lo studio

Sulla **macchina cBioPortal** (131.154.26.79):

```bash
# Decomprimi l'archivio
cd ~
tar -xzf melanoma_study.tar.gz
cd melanoma_study

# Esegui lo script di caricamento
chmod +x load_study_on_server.sh
./load_study_on_server.sh
```

Lo script farà automaticamente:
- ✓ Verifica container attivo
- ✓ Copia file nel container
- ✓ Valida lo studio
- ✓ Carica in cBioPortal

#### 4. Riavvia il container

```bash
sudo docker restart cbioportal-container

# Attendi circa 2 minuti che il container si avvii
sleep 120

# Verifica che sia attivo
sudo docker ps | grep cbioportal
```

#### 5. Verifica sul web

Vai a: **http://131.154.26.79:9090**

Cerca: **"Melanoma COLO-829"** oppure **"COLO-829"**

---

### Opzione 2: Metodo Manuale (Passo-Passo)

Se vuoi maggiore controllo, ecco i comandi individuali:

#### 1. Copia nel container Docker

```bash
# Sulla macchina cBioPortal
sudo docker cp ~/melanoma_study cbioportal-container:/data/

# Verifica che i file ci siano
sudo docker exec cbioportal-container ls -lh /data/melanoma_study/
```

#### 2. Validazione (opzionale ma consigliata)

```bash
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    python3 validateData.py -s /data/melanoma_study -html /data/validation_report.html
"

# Copia il report di validazione per controllarlo
sudo docker cp cbioportal-container:/data/validation_report.html /tmp/
```

Se ci sono errori, il report HTML te li mostrerà. Gli errori comuni sono:
- Colonne mancanti nel MAF
- IDs non corrispondenti tra file clinici e MAF
- Formato date errato

#### 3. Caricamento in cBioPortal

```bash
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    ./metaImport.py -s /data/melanoma_study
"
```

Vedrai output tipo:
```
Reading study file /data/melanoma_study/meta_study.txt
Reading cancer type file...
Processing clinical data...
Processing mutation data...
Import successful!
```

#### 4. Riavvio e verifica

```bash
sudo docker restart cbioportal-container
```

Attendi 2-3 minuti e vai su http://131.154.26.79:9090

---

## Risoluzione Problemi

### Lo studio non appare dopo il caricamento

```bash
# 1. Controlla i log del container
sudo docker logs cbioportal-container | tail -100

# 2. Controlla che il database MySQL sia OK
sudo docker exec cbioportal-container bash -c "
    mysql -u cbio_user -pP@ssword1 cbioportal -e 'SHOW TABLES;'
"

# 3. Verifica che lo studio sia nel database
sudo docker exec cbioportal-container bash -c "
    mysql -u cbio_user -pP@ssword1 cbioportal -e \
    'SELECT * FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER=\"melanoma_colo829_test\";'
"
```

### Errore di validazione

Il report HTML in `/tmp/validation_report.html` ti dirà esattamente cosa c'è di sbagliato.

Errori comuni:
- **Colonne mancanti**: aggiungi le colonne richieste al MAF
- **SAMPLE_ID non trovato**: assicurati che i sample IDs nel MAF corrispondano a quelli in `data_clinical_sample.txt`
- **PATIENT_ID mismatch**: controlla che i patient IDs siano consistenti

### Ricaricamento dello studio

Se devi ricaricare dopo aver fatto modifiche:

```bash
# 1. Cancella lo studio esistente
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    ./cbioportalImporter.py -c remove-study -id melanoma_colo829_test
"

# 2. Ricarica
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    ./metaImport.py -s /data/melanoma_study
"

# 3. Riavvia
sudo docker restart cbioportal-container
```

---

## Cosa Aspettarsi

Una volta caricato, dovresti vedere:

### 1. Nella homepage di cBioPortal
- Studio "Melanoma COLO-829 Test Case" nella lista

### 2. Nella pagina dello studio
- 1 paziente
- 2 campioni (1 tumore + 1 normale)
- 36 mutazioni totali
- Mutazione BRAF V600E evidenziata

### 3. Nel query interface
- Possibilità di selezionare geni (es. BRAF, PTEN)
- Visualizzazione OncoPrint
- Mutation table con tutte le 36 mutazioni
- Patient view con timeline

---

## Note Tecniche

### Database
- cBioPortal usa MySQL 8.0
- Container: `cbioportal-database-container`
- Database: `cbioportal`
- User: `cbio_user`

### Porte
- cBioPortal web: 9090
- MySQL: 3306

### Versione
- cBioPortal: 6.2.0
- Session Service: 0.6.1

### Limiti
- Questo è un ambiente di test
- Non caricare dati sensibili reali
- Backup regolari consigliati

---

## Comandi Utili

```bash
# Stato container
sudo docker ps

# Log container cBioPortal
sudo docker logs -f cbioportal-container

# Log MySQL
sudo docker logs -f cbioportal-database-container

# Accesso MySQL
sudo docker exec -it cbioportal-database-container \
    mysql -u cbio_user -pP@ssword1 cbioportal

# Lista studi nel database
sudo docker exec cbioportal-container bash -c "
    mysql -u cbio_user -pP@ssword1 cbioportal -e \
    'SELECT CANCER_STUDY_IDENTIFIER, NAME FROM cancer_study;'
"

# Spazio disco container
sudo docker exec cbioportal-container df -h

# Restart tutti i container
sudo docker restart cbioportal-container cbioportal-database-container
```

---

## Riferimenti

- Documentazione cBioPortal: https://docs.cbioportal.org/data-loading/
- Formati file: https://docs.cbioportal.org/file-formats/
- COLO-829 reference: https://pubmed.ncbi.nlm.nih.gov/32913971/
- Repository management: https://gitlab.com/bucci.g/cbioportal-management

---

## Supporto

Per problemi:
1. Controlla validation_report.html
2. Controlla i log del container
3. Verifica il database MySQL
4. Consulta la documentazione ufficiale cBioPortal

Buon caricamento! 🚀
