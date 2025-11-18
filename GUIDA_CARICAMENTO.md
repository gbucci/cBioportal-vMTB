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

Vai a: **http://131.154.26.79:8080/cbioportal** oppure **http://acc-vmtb.cnaf.infn.it/cbioportal**

Dopo il login con Keycloak, cerca: **"Melanoma COLO-829"** oppure **"COLO-829"**

---

### Opzione 2: Metodo Manuale (Passo-Passo)

Se vuoi maggiore controllo, ecco i comandi individuali testati e funzionanti:

#### 1. Connessione alla macchina

```bash
# Dalla tua macchina locale
ssh -i ~/.ssh/id_ed25519.pub \
    -J gbucci@bastion-sgsi.cnaf.infn.it \
    -l ubuntu 131.154.26.79
```

Ti verrà chiesto:
1. First Factor: password INFN
2. Second Factor: codice OTP

#### 2. Estrazione dello studio

```bash
# Sulla macchina cBioPortal (ubuntu@mtb-app)
cd ~
tar -xzf melanoma_study.tar.gz

# Verifica l'estrazione
ls -lh melanoma_study/
```

#### 3. Pulizia e copia nel container Docker

```bash
# Pulisci la directory /data nel container (se necessario)
sudo docker exec cbioportal-container bash -c "rm -rf /data/*"

# Copia lo studio nel container
sudo docker cp ~/melanoma_study cbioportal-container:/data/

# Verifica che i file ci siano
sudo docker exec cbioportal-container ls -lh /data/melanoma_study/
```

Output atteso: lista di tutti i file dello studio (meta_study.txt, data_mutations_extended.maf, etc.)

#### 4. Import diretto in cBioPortal (SENZA validazione API)

**IMPORTANTE**: Il server cBioPortal ha autenticazione Keycloak che impedisce l'accesso all'API `/api/info` durante l'import. Usa queste opzioni:

```bash
sudo docker exec cbioportal-container metaImport.py -s /data/melanoma_study -n -o
```

**Opzioni utilizzate:**
- `-s /data/melanoma_study`: percorso dello studio nel container
- `-n` (`--no_portal_checks`): **salta i controlli che richiedono l'API web** (necessario!)
- `-o` (`--override_warning`): ignora i warning e procede con l'import

Output atteso:
```
Starting validation...
INFO: -: Validation complete
#######################################################################
Overriding Warnings. Importing study now
#######################################################################

Data loading step using /core/core-1.0.9.jar
...
--> Loaded 1 new cancer types.
--> Study ID:  X
--> Name:  Melanoma COLO-829 Test Case
...
--> records inserted into `mutation` table: 33
...
Done.
```

**Note:**
- 33 mutazioni verranno caricate (2 filtrate automaticamente: 5'Flank e Intron)
- Il processo richiede circa 20-30 secondi

#### 5. Verifica dal Database MySQL

**IMPORTANTE**: Le credenziali del database sono:
- User: `cbio_user`
- Password: `somepassword` (NON `P@ssword1`)
- Container: `cbioportal-database-container` (NON `cbioportal-container`)

```bash
# Verifica studio caricato
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e \
"SELECT CANCER_STUDY_ID, CANCER_STUDY_IDENTIFIER, NAME, DESCRIPTION FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='melanoma_colo829_test';"

# Conta mutazioni caricate
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e \
"SELECT COUNT(*) as Mutazioni_Caricate FROM mutation WHERE GENETIC_PROFILE_ID IN (SELECT GENETIC_PROFILE_ID FROM genetic_profile WHERE CANCER_STUDY_ID = (SELECT CANCER_STUDY_ID FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='melanoma_colo829_test'));"

# Verifica campioni
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e \
"SELECT STABLE_ID FROM sample WHERE PATIENT_ID IN (SELECT INTERNAL_ID FROM patient WHERE CANCER_STUDY_ID = (SELECT CANCER_STUDY_ID FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='melanoma_colo829_test'));"

# Lista tutti gli studi
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e \
"SELECT CANCER_STUDY_ID, CANCER_STUDY_IDENTIFIER, NAME FROM cancer_study;"
```

Output atteso:
- Studio: melanoma_colo829_test
- Mutazioni: 33
- Campioni: COLO-829, COLO-829BL

#### 6. Riavvio container (opzionale)

```bash
sudo docker restart cbioportal-container
```

Attendi 2-3 minuti e vai su **http://131.154.26.79:8080/cbioportal** o **http://acc-vmtb.cnaf.infn.it/cbioportal**

---

## Risoluzione Problemi

### Errore: "Connection refused" o "401 Unauthorized" durante l'import

**Causa:** metaImport.py sta cercando di connettersi all'API `/api/info` che richiede autenticazione Keycloak

**Soluzione:** Usa sempre le opzioni `-n -o`:
```bash
sudo docker exec cbioportal-container metaImport.py -s /data/melanoma_study -n -o
```

### Errore: "Access denied for user 'cbio_user'"

**Causa:** Password del database errata

**Soluzione:** Usa la password corretta `somepassword`:
```bash
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "..."
```

### Errore: "Can't connect to MySQL server through socket"

**Causa:** Comando MySQL eseguito nel container sbagliato

**Soluzione:** Usa `cbioportal-database-container` (NON `cbioportal-container`):
```bash
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword ...
```

### Lo studio non appare dopo il caricamento

```bash
# 1. Controlla i log del container
sudo docker logs cbioportal-container | tail -100

# 2. Verifica che lo studio sia nel database
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e \
"SELECT * FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='melanoma_colo829_test';"

# 3. Controlla le tabelle del database
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "SHOW TABLES;"
```

### Ricaricamento dello studio

Se devi ricaricare dopo aver fatto modifiche:

```bash
# 1. Cancella lo studio esistente
sudo docker exec cbioportal-container bash -c "
    cd /core/scripts/importer && \
    ./cbioportalImporter.py -c remove-study -id melanoma_colo829_test
"

# 2. Ricarica con le opzioni corrette
sudo docker exec cbioportal-container metaImport.py -s /data/melanoma_study -n -o

# 3. Riavvia (opzionale)
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

### Ambiente INFN (ubuntu@mtb-app, 131.154.26.79)

**Container Docker:**
```
cbioportal-container            (cbioportal/cbioportal:4.1.13)
cbioportal-database-container   (mysql:5.7)
cbioportal-session-container    (cbioportal/session-service:0.5.0)
cbioportal-session-database-container (mongo:3.7.9)
```

**Versioni:**
- cBioPortal: **4.1.13**
- MySQL: **5.7** (NON 8.0!)
- Session Service: 0.5.0

**Database:**
- Container: `cbioportal-database-container`
- Database: `cbioportal`
- User: `cbio_user`
- Password: **`somepassword`** (NON `P@ssword1`!)

**Porte e URL:**
- cBioPortal web: **8080** (NON 9090!)
- MySQL: 3306
- URL interno: `http://131.154.26.79:8080/cbioportal`
- URL esterno: `http://acc-vmtb.cnaf.infn.it/cbioportal`

**Autenticazione:**
- Sistema: Keycloak
- Realm: vmtb
- Keycloak URL: `https://acc-kc.cnaf.infn.it/auth/realms/vmtb`

**Percorsi nel container:**
- Script import: `/usr/local/bin/` o `/core/scripts/importer/`
- Studi: `/data/`
- Core JAR: `/core/core-1.0.9.jar`

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
sudo docker logs cbioportal-database-container

# Accesso MySQL interattivo
sudo docker exec -it cbioportal-database-container \
    mysql -u cbio_user -psomepassword cbioportal

# Lista studi nel database
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e \
"SELECT CANCER_STUDY_IDENTIFIER, NAME FROM cancer_study;"

# Conta mutazioni per studio
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e \
"SELECT COUNT(*) FROM mutation WHERE GENETIC_PROFILE_ID IN (SELECT GENETIC_PROFILE_ID FROM genetic_profile WHERE CANCER_STUDY_ID = (SELECT CANCER_STUDY_ID FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='melanoma_colo829_test'));"

# Verifica variabili d'ambiente del database
sudo docker exec cbioportal-database-container env | grep -i MYSQL

# Spazio disco container
sudo docker exec cbioportal-container df -h

# Restart container cBioPortal
sudo docker restart cbioportal-container
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
