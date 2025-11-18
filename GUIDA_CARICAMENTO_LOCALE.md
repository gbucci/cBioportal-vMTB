# Guida Caricamento Studio su cBioPortal Locale (172.21.91.6)

Questa guida descrive i passaggi per caricare lo studio melanoma COLO-829 sulla macchina locale cBioPortal durante il downtime del server INFN.

---

## Informazioni Ambiente Locale

- **Server**: 172.21.91.6 (wrkctgb001)
- **User**: gbucci
- **cBioPortal Version**: 4.1.13
- **Porta Web**: 8080
- **Base Path**: /cbioportal
- **Database**: MySQL 8.0 (container separato)
- **Credenziali DB**:
  - User: `cbio_user`
  - Password: `somepassword`
  - Database: `cbioportal`

---

## Container Docker in Esecuzione

```bash
CONTAINER ID   IMAGE                              PORTS                    NAMES
457694403f88   cbioportal/cbioportal:4.1.13       0.0.0.0:8080->8080/tcp   cbioportal-container
d4a93661f364   cbioportal/session-service:0.5.0                            cbioportal-session-container
6deaa73c4800   mongo:3.7.9                        27017/tcp                cbioportal-session-database-container
007e5f19daeb   mysql:5.7                          3306/tcp, 33060/tcp      cbioportal-database-container
```

---

## PASSAGGI COMPLETI

### **STEP 1: Trasferimento File sulla Macchina Locale**

Dalla macchina di sviluppo, trasferisci lo studio e lo script adattato:

```bash
cd /home/user/cBioportal-vMTB

# Trasferimento via SCP
scp melanoma_study.tar.gz load_study_on_local.sh gbucci@172.21.91.6:~/
```

---

### **STEP 2: Connessione alla Macchina Locale**

```bash
ssh gbucci@172.21.91.6
```

---

### **STEP 3: Estrazione dello Studio**

```bash
cd ~
tar -xzf melanoma_study.tar.gz
```

Verifica l'estrazione:
```bash
ls -lh melanoma_study/
```

Output atteso:
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

### **STEP 4: Copia dello Studio nel Container Docker**

```bash
# Pulisci la directory /data nel container (se necessario)
sudo docker exec cbioportal-container bash -c "rm -rf /data/*"

# Copia lo studio nel container
sudo docker cp ~/melanoma_study cbioportal-container:/data/

# Verifica che i file siano stati copiati correttamente
sudo docker exec cbioportal-container ls -lh /data/melanoma_study/
```

Output atteso: lista di tutti i file dello studio.

---

### **STEP 5: Import dello Studio in cBioPortal**

Usa il comando `metaImport.py` con le opzioni per saltare i controlli API:

```bash
sudo docker exec cbioportal-container metaImport.py -s /data/melanoma_study -n -o
```

**Opzioni utilizzate:**
- `-s /data/melanoma_study`: percorso dello studio nel container
- `-n` (`--no_portal_checks`): salta i controlli che richiedono l'API web (necessario perché l'API richiede autenticazione Keycloak)
- `-o` (`--override_warning`): ignora i warning e procede con l'import

**Output atteso:**
```
Starting validation...
...
INFO: -: Validation complete
#######################################################################
Overriding Warnings. Importing study now
#######################################################################

Data loading step using /core/core-1.0.9.jar
...
--> Loaded 1 new cancer types.
...
--> Study ID:  7
--> Name:  Melanoma COLO-829 Test Case
...
--> records inserted into `mutation` table: 33
...
Done.
```

---

### **STEP 6: Verifica del Caricamento dal Database**

Verifica che lo studio sia stato importato correttamente interrogando il database MySQL:

#### **6.1 - Verifica dello studio caricato**

```bash
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "SELECT CANCER_STUDY_ID, CANCER_STUDY_IDENTIFIER, NAME, DESCRIPTION FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='melanoma_colo829_test';"
```

Output atteso:
```
CANCER_STUDY_ID	CANCER_STUDY_IDENTIFIER	NAME	DESCRIPTION
7	melanoma_colo829_test	Melanoma COLO-829 Test Case	Test study with melanoma case COLO-829 with BRAF V600E mutation and resistance to vemurafenib
```

#### **6.2 - Conta delle mutazioni caricate**

```bash
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "SELECT COUNT(*) as Mutazioni_Caricate FROM mutation WHERE GENETIC_PROFILE_ID IN (SELECT GENETIC_PROFILE_ID FROM genetic_profile WHERE CANCER_STUDY_ID = (SELECT CANCER_STUDY_ID FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='melanoma_colo829_test'));"
```

Output atteso:
```
Mutazioni_Caricate
33
```

#### **6.3 - Verifica campioni**

```bash
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "SELECT STABLE_ID FROM sample WHERE PATIENT_ID IN (SELECT INTERNAL_ID FROM patient WHERE CANCER_STUDY_ID = (SELECT CANCER_STUDY_ID FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='melanoma_colo829_test'));"
```

Output atteso:
```
STABLE_ID
COLO-829
COLO-829BL
```

#### **6.4 - Lista di tutti gli studi nel database**

```bash
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "SELECT CANCER_STUDY_ID, CANCER_STUDY_IDENTIFIER, NAME FROM cancer_study;"
```

Output atteso:
```
CANCER_STUDY_ID	CANCER_STUDY_IDENTIFIER	NAME
5	lgg_ucsf_2014	Low-Grade Gliomas (UCSF, Science 2014)
6	aml_ohsu_2018	Acute Myeloid Leukemia (OHSU, Nature 2018)
7	melanoma_colo829_test	Melanoma COLO-829 Test Case
```

---

### **STEP 7: Riavvio del Container (Opzionale)**

Per rendere lo studio visibile nell'interfaccia web, riavvia il container cBioPortal:

```bash
sudo docker restart cbioportal-container
```

Attendi **2-3 minuti** per il completo riavvio dell'applicazione.

---

### **STEP 8: Accesso Web**

Una volta rimossi i filtri IP, accedi all'interfaccia web:

**URL interno:**
```
http://172.21.91.6:8080/cbioportal
```

**URL esterno:**
```
http://acc-vmtb.cnaf.infn.it/cbioportal
```

Dopo il login con Keycloak, cerca **"Melanoma COLO-829"** per accedere allo studio.

---

## Riepilogo Dati Caricati

| Elemento | Valore |
|----------|--------|
| **Study ID** | 7 |
| **Identificatore** | melanoma_colo829_test |
| **Nome** | Melanoma COLO-829 Test Case |
| **Mutazioni** | 33 (35 totali - 2 filtrate: 5'Flank, Intron) |
| **Campioni** | 2 (COLO-829, COLO-829BL) |
| **Pazienti** | 1 (C_UFLEBTVLHO) |
| **Case Lists** | 2 (all, sequenced) |

---

## Note Importanti

### **Differenze rispetto al Server INFN (131.154.26.79)**

| Aspetto | Server INFN | Macchina Locale |
|---------|-------------|-----------------|
| **cBioPortal Version** | 6.2.0 | 4.1.13 |
| **Porta Web** | 9090 | 8080 |
| **Database** | MySQL 8.0 | MySQL 5.7 |
| **Password DB** | P@ssword1 | somepassword |
| **Base Path** | /cbioportal | /cbioportal |
| **Autenticazione** | Keycloak | Keycloak |

### **Script di Import**

- Lo script `metaImport.py` sulla versione 4.1.13 richiede obbligatoriamente le opzioni `-n -o` per funzionare senza accesso all'API web
- La validazione viene eseguita automaticamente prima dell'import
- L'API `/api/info` richiede autenticazione Keycloak (401 Unauthorized) quindi non è accessibile durante l'import

### **Comandi Utili**

```bash
# Verifica stato container
sudo docker ps | grep cbioportal

# Log del container cBioPortal
sudo docker logs -f cbioportal-container

# Log del database
sudo docker logs cbioportal-database-container

# Rimozione studio (per ricaricare)
sudo docker exec cbioportal-container bash -c "
    cd /core/scripts/importer && \
    ./cbioportalImporter.py -c remove-study -id melanoma_colo829_test
"
```

---

## Troubleshooting

### Errore: "Connection refused" durante l'import

**Causa:** metaImport.py sta cercando di connettersi all'API su porta 80 invece di 8080

**Soluzione:** Usa le opzioni `-n` per saltare i controlli dell'API

### Errore: "401 Unauthorized" per /api/info

**Causa:** L'API richiede autenticazione Keycloak

**Soluzione:** Usa `-n` per evitare il controllo dell'API

### Errore: "Access denied for user 'cbio_user'"

**Causa:** Password del database errata

**Soluzione:** Usa `somepassword` invece di `P@ssword1`

### Errore: "Can't connect to MySQL server through socket"

**Causa:** Comando MySQL eseguito nel container sbagliato

**Soluzione:** Usa `cbioportal-database-container` invece di `cbioportal-container`

---

## File Creati

- **load_study_on_local.sh**: Script automatizzato per caricamento (adattato per ambiente locale)
- **GUIDA_CARICAMENTO_LOCALE.md**: Questa guida

---

**Data ultimo aggiornamento:** 18 Novembre 2025
**Versione cBioPortal:** 4.1.13
**Ambiente:** Macchina locale 172.21.91.6 (wrkctgb001)
