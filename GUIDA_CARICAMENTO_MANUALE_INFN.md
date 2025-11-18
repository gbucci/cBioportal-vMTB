# Guida Caricamento Manuale - Server INFN cBioPortal

Questa guida documenta i passaggi manuali eseguiti con successo per caricare lo studio melanoma COLO-829 sul server cBioPortal INFN.

**Data:** 18 Novembre 2025
**Ambiente:** Server INFN (ubuntu@mtb-app, 131.154.26.79)
**Risultato:** ✅ 33 mutazioni caricate con successo

---

## Informazioni Ambiente

### Server
- **Host**: ubuntu@mtb-app (131.154.26.79)
- **Accesso**: Via bastion INFN con autenticazione 2FA
- **User**: ubuntu

### cBioPortal
- **Versione**: 4.1.13 (NON 6.2.0!)
- **Porta**: 8080 (NON 9090!)
- **Base Path**: `/cbioportal`
- **URL Interno**: http://131.154.26.79:8080/cbioportal
- **URL Esterno**: http://acc-vmtb.cnaf.infn.it/cbioportal
- **Autenticazione**: Keycloak (realm: vmtb)

### Container Docker
```
CONTAINER ID   IMAGE                              PORTS                    NAMES
457694403f88   cbioportal/cbioportal:4.1.13       0.0.0.0:8080->8080/tcp   cbioportal-container
d4a93661f364   cbioportal/session-service:0.5.0                            cbioportal-session-container
6deaa73c4800   mongo:3.7.9                        27017/tcp                cbioportal-session-database-container
007e5f19daeb   mysql:5.7                          3306/tcp, 33060/tcp      cbioportal-database-container
```

### Database
- **Container**: `cbioportal-database-container`
- **Engine**: MySQL 5.7 (NON 8.0!)
- **Database**: `cbioportal`
- **User**: `cbio_user`
- **Password**: `somepassword` (NON `P@ssword1`!)

---

## PASSAGGI ESEGUITI CON SUCCESSO

### **STEP 1: Connessione al Server INFN**

Dal tuo computer locale:

```bash
ssh -i ~/.ssh/id_ed25519.pub \
    -J gbucci@bastion-sgsi.cnaf.infn.it \
    -l ubuntu 131.154.26.79
```

**Autenticazione richiesta:**
1. **First Factor**: Password INFN
2. **Second Factor**: Codice OTP (app Authenticator)

---

### **STEP 2: Estrazione dello Studio**

Sul server INFN (ubuntu@mtb-app):

```bash
cd ~
tar -xzf melanoma_study.tar.gz
```

**Verifica estrazione:**
```bash
ls -lh melanoma_study/
```

**Output atteso:**
```
cancer_type.txt
case_lists/
data_clinical_patient.txt
data_clinical_sample.txt
data_mutations_extended.maf
meta_cancer_type.txt
meta_clinical_patient.txt
meta_clinical_sample.txt
meta_mutations_extended.txt
meta_study.txt
README.md
```

---

### **STEP 3: Pulizia Directory nel Container**

```bash
# Pulisci la directory /data nel container
sudo docker exec cbioportal-container bash -c "rm -rf /data/*"
```

**Note**: Questo comando è necessario se ci sono file residui da import precedenti.

---

### **STEP 4: Copia dello Studio nel Container**

```bash
# Copia lo studio dalla home al container
sudo docker cp ~/melanoma_study cbioportal-container:/data/
```

**Verifica copia:**
```bash
sudo docker exec cbioportal-container ls -lh /data/melanoma_study/
```

**Output atteso:**
```
total 112K
-rw------- 1 ubuntu ubuntu   31 Nov 17 17:00 cancer_type.txt
drwxr-xr-x 2 ubuntu ubuntu 4.0K Nov 18 14:57 case_lists
-rw------- 1 ubuntu ubuntu  241 Nov 17 17:00 data_clinical_patient.txt
-rw------- 1 ubuntu ubuntu  428 Nov 17 17:00 data_clinical_sample.txt
-rw------- 1 ubuntu ubuntu  66K Nov 17 17:00 data_mutations_extended.maf
-rw------- 1 ubuntu ubuntu   90 Nov 17 17:00 meta_cancer_type.txt
-rw------- 1 ubuntu ubuntu  151 Nov 17 17:00 meta_clinical_patient.txt
-rw------- 1 ubuntu ubuntu  149 Nov 17 17:00 meta_clinical_sample.txt
-rw------- 1 ubuntu ubuntu  295 Nov 17 17:00 meta_mutations_extended.txt
-rw------- 1 ubuntu ubuntu  290 Nov 17 17:10 meta_study.txt
-rw------- 1 ubuntu ubuntu 1016 Nov 17 17:00 README.md
```

---

### **STEP 5: Import dello Studio**

**IMPORTANTE**: Il server ha autenticazione Keycloak che impedisce l'accesso all'API `/api/info`. Devi usare le opzioni `-n -o`:

```bash
sudo docker exec cbioportal-container metaImport.py -s /data/melanoma_study -n -o
```

**Spiegazione opzioni:**
- `-s /data/melanoma_study`: percorso dello studio nel container
- `-n` (`--no_portal_checks`): **salta i controlli API** (necessario perché `/api/info` richiede autenticazione Keycloak)
- `-o` (`--override_warning`): ignora i warning e procede con l'import

**Output completo atteso:**

```
Starting validation...

WARNING: -: Skipping validations relating to cancer types defined in the portal
WARNING: -: Skipping validations relating to gene identifiers and aliases defined in the portal
WARNING: -: Skipping validations relating to gene set identifiers
WARNING: -: Skipping validations relating to gene panel identifiers

INFO: meta_cancer_type.txt: Validation of meta file complete
INFO: meta_clinical_patient.txt: Validation of meta file complete
INFO: meta_clinical_sample.txt: Validation of meta file complete
INFO: meta_mutations_extended.txt: Validation of meta file complete
INFO: meta_study.txt: Validation of meta file complete
INFO: meta_study.txt: Setting reference genome to human (GRCh38, hg38)

INFO: cancer_type.txt: Validation of file complete
INFO: cancer_type.txt: Read 1 lines. Lines with warning: 0. Lines with error: 0

INFO: data_clinical_sample.txt: Validation of file complete
INFO: data_clinical_sample.txt: Read 7 lines. Lines with warning: 0. Lines with error: 0

INFO: case_lists/melanoma_colo829_test_sequenced.txt: Validation of meta file complete
INFO: case_lists/melanoma_colo829_test_all.txt: Validation of meta file complete
INFO: -: Validation of case list folder complete

WARNING: data_clinical_patient.txt: Columns OS_MONTHS and/or OS_STATUS not found.
WARNING: data_clinical_patient.txt: Columns DFS_MONTHS and/or DFS_STATUS not found.
INFO: data_clinical_patient.txt: Validation of file complete
INFO: data_clinical_patient.txt: Read 6 lines. Lines with warning: 0. Lines with error: 0

WARNING: data_mutations_extended.maf: column 68: A SWISSPROT column was found...
INFO: data_mutations_extended.maf: lines [16, 18]: Line will not be loaded due to variant classification filter.
INFO: data_mutations_extended.maf: Validation of file complete
INFO: data_mutations_extended.maf: Read 37 lines. Lines with warning: 33. Lines with error: 0

INFO: -: Validation complete
#######################################################################
Overriding Warnings. Importing study now
#######################################################################

Data loading step using /core/core-1.0.9.jar

> /opt/java/openjdk/bin/java [...] org.mskcc.cbio.portal.scripts.ImportTypesOfCancers [...]
--> Loaded 1 new cancer types.
Done.

> /opt/java/openjdk/bin/java [...] org.mskcc.cbio.portal.scripts.ImportCancerStudy [...]
Loaded the following cancer study:
--> Study ID:  7
--> Name:  Melanoma COLO-829 Test Case
--> Description:  Test study with melanoma case COLO-829 with BRAF V600E mutation
Done.

> /opt/java/openjdk/bin/java [...] org.mskcc.cbio.portal.scripts.ImportClinicalData [...]
--> records inserted into `clinical_sample` table: 7
Total number of samples processed:  2
Done.

> /opt/java/openjdk/bin/java [...] org.mskcc.cbio.portal.scripts.ImportClinicalData [...]
--> records inserted into `clinical_patient` table: 3
Done.

> /opt/java/openjdk/bin/java [...] org.mskcc.cbio.portal.scripts.ImportProfileData [...]
--> records inserted into `mutation_event` table: 33
--> records inserted into `mutation` table: 33
--> total number of data entries skipped: 2
Filtering table:
5'Flank Rejects: 1
Intron Rejects: 1
Done.

> /opt/java/openjdk/bin/java [...] org.mskcc.cbio.portal.scripts.ImportSampleList [...]
--> stable ID:  melanoma_colo829_test_sequenced
--> number of samples stored in final sample list: 1
Done.

> /opt/java/openjdk/bin/java [...] org.mskcc.cbio.portal.scripts.ImportSampleList [...]
--> stable ID:  melanoma_colo829_test_all
--> number of samples stored in final sample list: 2
Done.

> /opt/java/openjdk/bin/java [...] org.mskcc.cbio.portal.scripts.UpdateCancerStudy [...]
Updating study status to: 'AVAILABLE' for study: melanoma_colo829_test
Done.
```

**Riepilogo import:**
- ✅ 1 cancer type caricato
- ✅ Studio creato (ID: 7)
- ✅ 2 campioni caricati
- ✅ 1 paziente caricato
- ✅ **33 mutazioni** caricate (2 filtrate: 5'Flank, Intron)
- ✅ 2 case lists caricate
- ✅ Studio impostato come AVAILABLE

---

### **STEP 6: Verifica dal Database MySQL**

**IMPORTANTE**: Usa il container `cbioportal-database-container` con password `somepassword`

#### **6.1 - Verifica studio caricato**

```bash
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e \
"SELECT CANCER_STUDY_ID, CANCER_STUDY_IDENTIFIER, NAME, DESCRIPTION FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='melanoma_colo829_test';"
```

**Output:**
```
mysql: [Warning] Using a password on the command line interface can be insecure.
CANCER_STUDY_ID	CANCER_STUDY_IDENTIFIER	NAME	DESCRIPTION
7	melanoma_colo829_test	Melanoma COLO-829 Test Case	Test study with melanoma case COLO-829 with BRAF V600E mutation and resistance to vemurafenib
```

#### **6.2 - Conta mutazioni caricate**

```bash
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e \
"SELECT COUNT(*) as Mutazioni_Caricate FROM mutation WHERE GENETIC_PROFILE_ID IN (SELECT GENETIC_PROFILE_ID FROM genetic_profile WHERE CANCER_STUDY_ID = (SELECT CANCER_STUDY_ID FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='melanoma_colo829_test'));"
```

**Output:**
```
Mutazioni_Caricate
33
```

#### **6.3 - Verifica campioni**

```bash
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e \
"SELECT STABLE_ID FROM sample WHERE PATIENT_ID IN (SELECT INTERNAL_ID FROM patient WHERE CANCER_STUDY_ID = (SELECT CANCER_STUDY_ID FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='melanoma_colo829_test'));"
```

**Output:**
```
STABLE_ID
COLO-829
COLO-829BL
```

#### **6.4 - Lista tutti gli studi nel database**

```bash
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e \
"SELECT CANCER_STUDY_ID, CANCER_STUDY_IDENTIFIER, NAME FROM cancer_study;"
```

**Output:**
```
CANCER_STUDY_ID	CANCER_STUDY_IDENTIFIER	NAME
5	lgg_ucsf_2014	Low-Grade Gliomas (UCSF, Science 2014)
6	aml_ohsu_2018	Acute Myeloid Leukemia (OHSU, Nature 2018)
7	melanoma_colo829_test	Melanoma COLO-829 Test Case
```

---

### **STEP 7: Riavvio Container (Opzionale)**

```bash
sudo docker restart cbioportal-container
```

**Attendi 2-3 minuti** per il riavvio completo.

---

### **STEP 8: Accesso Web**

Una volta rimossi i filtri IP o da una rete autorizzata:

**URL Interno:**
```
http://131.154.26.79:8080/cbioportal
```

**URL Esterno:**
```
http://acc-vmtb.cnaf.infn.it/cbioportal
```

1. Login con Keycloak
2. Cerca "Melanoma COLO-829" o "COLO-829"
3. Esplora le 33 mutazioni inclusa BRAF V600E

---

## Riepilogo Dati Caricati

| Elemento | Valore |
|----------|--------|
| **Study ID** | 7 |
| **Identificatore** | melanoma_colo829_test |
| **Nome** | Melanoma COLO-829 Test Case |
| **Mutazioni** | 33 (su 35 totali) |
| **Mutazioni filtrate** | 2 (5'Flank: 1, Intron: 1) |
| **Campioni** | 2 (COLO-829, COLO-829BL) |
| **Pazienti** | 1 (C_UFLEBTVLHO) |
| **Case Lists** | 2 (all: 2 samples, sequenced: 1 sample) |
| **Genoma** | GRCh38/hg38 |

---

## Troubleshooting - Errori Comuni

### Errore: "Connection refused" o "401 Unauthorized"

**Messaggio completo:**
```
ConnectionError: Failed to fetch metadata from the portal at [http://localhost:8080/cbioportal/api/info]
requests.exceptions.HTTPError: 401 Client Error
```

**Causa:** metaImport.py cerca di accedere all'API che richiede autenticazione Keycloak

**Soluzione:** Usa SEMPRE le opzioni `-n -o`:
```bash
sudo docker exec cbioportal-container metaImport.py -s /data/melanoma_study -n -o
```

### Errore: "Access denied for user 'cbio_user'"

**Messaggio completo:**
```
ERROR 1045 (28000): Access denied for user 'cbio_user'@'localhost' (using password: YES)
```

**Causa:** Password errata

**Soluzione:** Usa `somepassword` NON `P@ssword1`:
```bash
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "..."
```

### Errore: "Can't connect to MySQL server through socket"

**Messaggio completo:**
```
ERROR 2002 (HY000): Can't connect to local MySQL server through socket '/var/run/mysqld/mysqld.sock' (2)
```

**Causa:** Stai usando il container sbagliato

**Soluzione:** Usa `cbioportal-database-container` NON `cbioportal-container`:
```bash
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword ...
```

### Errore: "ls: cannot access '/data/melanoma_study/'"

**Causa:** Lo studio è stato copiato direttamente in `/data/` invece che in `/data/melanoma_study/`

**Soluzione:**
```bash
# Opzione 1: Pulisci e ricopia
sudo docker exec cbioportal-container bash -c "rm -rf /data/*"
sudo docker cp ~/melanoma_study cbioportal-container:/data/

# Opzione 2: Sposta i file
sudo docker exec cbioportal-container mkdir -p /data/melanoma_study
sudo docker exec cbioportal-container bash -c "mv /data/*.txt /data/*.maf /data/README.md /data/case_lists /data/melanoma_study/"
```

---

## Comandi Utili

### Verifica Container

```bash
# Stato di tutti i container
sudo docker ps

# Verifica specifico container
sudo docker ps | grep cbioportal
```

### Log e Debugging

```bash
# Log container cBioPortal (ultimi 50 log)
sudo docker logs --tail 50 cbioportal-container

# Log in tempo reale
sudo docker logs -f cbioportal-container

# Log database
sudo docker logs cbioportal-database-container
```

### Database MySQL

```bash
# Accesso interattivo
sudo docker exec -it cbioportal-database-container \
    mysql -u cbio_user -psomepassword cbioportal

# Lista tabelle
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "SHOW TABLES;"

# Verifica credenziali
sudo docker exec cbioportal-database-container env | grep -i MYSQL
```

### Gestione Studi

```bash
# Rimozione studio (per ricaricare)
sudo docker exec cbioportal-container bash -c "
    cd /core/scripts/importer && \
    ./cbioportalImporter.py -c remove-study -id melanoma_colo829_test
"

# Import con opzioni corrette
sudo docker exec cbioportal-container metaImport.py -s /data/melanoma_study -n -o
```

---

## Note Importanti

### Differenze Documentazione vs Realtà

La documentazione originale CLAUDE.md conteneva informazioni **non aggiornate**:

| Aspetto | Documentato | Realtà |
|---------|-------------|--------|
| Versione cBioPortal | 6.2.0 | **4.1.13** |
| Database | MySQL 8.0 | **MySQL 5.7** |
| Porta Web | 9090 | **8080** |
| Password DB | P@ssword1 | **somepassword** |
| Import Script | Con validazione API | **Richiede -n -o** |

### Percorsi Script nel Container

Gli script sono disponibili in due posizioni:
- `/usr/local/bin/` (link simbolici)
- `/core/scripts/importer/` (originali)

Entrambi funzionano. Usare direttamente `metaImport.py` senza path completo.

### Autenticazione Keycloak

Il server usa Keycloak per l'autenticazione web:
- **Realm**: vmtb
- **URL**: https://acc-kc.cnaf.infn.it/auth/realms/vmtb
- **Client ID**: cbioportal

Questo impedisce l'accesso diretto all'API `/api/info` durante l'import.

---

## Riferimenti

- **Documentazione cBioPortal**: https://docs.cbioportal.org/
- **File Formats**: https://docs.cbioportal.org/file-formats/
- **Data Loading**: https://docs.cbioportal.org/data-loading/
- **COLO-829 Reference**: Nathanson et al. (2020) PMID: 32913971

---

**Guida verificata e testata il:** 18 Novembre 2025
**Autore:** Claude Code
**Ambiente:** Server INFN cBioPortal (ubuntu@mtb-app, 131.154.26.79)
