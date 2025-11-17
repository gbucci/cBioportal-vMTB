# Guida per Creare Nuovi Studi cBioPortal

Questa guida si basa sull'esperienza del caricamento dello studio melanoma COLO-829 e documenta il processo completo per creare e caricare nuovi studi.

## Indice

1. [Pre-requisiti](#pre-requisiti)
2. [Struttura File Richiesta](#struttura-file-richiesta)
3. [Template File](#template-file)
4. [Workflow Completo](#workflow-completo)
5. [Validazione e Troubleshooting](#validazione-e-troubleshooting)
6. [Checklist Finale](#checklist-finale)

## Pre-requisiti

### Informazioni Necessarie

Prima di iniziare, raccogli:

- **Study ID**: identificatore univoco (lowercase, no spazi, es. `lung_adenocarcinoma_2024`)
- **Cancer Type**: tipo di tumore (es. `luad`, `melanoma`, `brca`)
- **Genoma di riferimento**: hg19 o hg38
- **Dati paziente**: ID paziente, età, sesso, diagnosi
- **Dati campioni**: ID campione, tipo tessuto, purezza tumorale
- **Dati mutazioni**: file MAF con mutazioni somatiche

### Formato Dati Clinici

I dati clinici devono seguire questo formato (4 righe di header):

```
#Patient Identifier	Age	Sex	Diagnosis Year
#Patient Identifier	Age at Diagnosis	Sex	Diagnosis Year
#STRING	NUMBER	STRING	NUMBER
#1	1	1	1
PATIENT_001	55	Male	2024
PATIENT_002	62	Female	2023
```

## Struttura File Richiesta

```
nome_studio/
├── meta_study.txt                          # Metadati studio (SENZA add_global_case_list!)
├── meta_cancer_type.txt                    # Metadati tipo cancro
├── cancer_type.txt                         # Definizione tipo cancro (se nuovo)
├── meta_clinical_patient.txt               # Metadati clinici paziente
├── data_clinical_patient.txt               # Dati clinici paziente
├── meta_clinical_sample.txt                # Metadati clinici campioni
├── data_clinical_sample.txt                # Dati clinici campioni
├── meta_mutations_extended.txt             # Metadati mutazioni
├── data_mutations_extended.maf             # File MAF con mutazioni
├── case_lists/                             # IMPORTANTE: subdirectory!
│   ├── {study_id}_all.txt                  # Tutti i campioni
│   └── {study_id}_sequenced.txt            # Campioni con dati mutazioni
├── load_study_on_local.sh                  # Script di caricamento (opzionale)
└── README.md                               # Documentazione studio
```

## Template File

### meta_study.txt

```properties
type_of_cancer: luad
cancer_study_identifier: lung_study_2024
name: Lung Adenocarcinoma Study 2024
description: Sequenziamento WES di pazienti con adenocarcinoma polmonare
citation: Ospedale San Raffaele 2024
pmid: 
reference_genome: hg38
```

**⚠️ ATTENZIONE:** NON includere `add_global_case_list: true` → causa errori di duplicazione!

### meta_cancer_type.txt

```properties
genetic_alteration_type: CANCER_TYPE
datatype: CANCER_TYPE
data_filename: cancer_type.txt
```

### cancer_type.txt

Se il tipo di cancro non esiste già in cBioPortal:

```
luad	Lung Adenocarcinoma	LightBlue	Lung
```

Formato: `type_id	name	color	parent_type`

### meta_clinical_patient.txt

```properties
cancer_study_identifier: lung_study_2024
genetic_alteration_type: CLINICAL
datatype: PATIENT_ATTRIBUTES
data_filename: data_clinical_patient.txt
```

### data_clinical_patient.txt

```
#Patient Identifier	Age	Sex	Diagnosis Year	Smoking Status
#Patient Identifier	Age at Diagnosis	Sex	Year of Diagnosis	Smoking History
#STRING	NUMBER	STRING	NUMBER	STRING
#1	1	1	1	1
P001	65	Male	2024	Former
P002	58	Female	2023	Never
```

### meta_clinical_sample.txt

```properties
cancer_study_identifier: lung_study_2024
genetic_alteration_type: CLINICAL
datatype: SAMPLE_ATTRIBUTES
data_filename: data_clinical_sample.txt
```

### data_clinical_sample.txt

```
#Patient Identifier	Sample Identifier	Sample Type	Tissue Site	Tumor Purity
#Patient Identifier	Sample Identifier	Sample Type	Tissue Site	Tumor Purity Percentage
#STRING	STRING	STRING	STRING	NUMBER
#1	1	1	1	1
P001	S001_T	Primary	Lung	85
P001	S001_N	Normal	Blood	0
P002	S002_T	Metastasis	Liver	70
```

### meta_mutations_extended.txt

```properties
cancer_study_identifier: lung_study_2024
genetic_alteration_type: MUTATION_EXTENDED
datatype: MAF
stable_id: mutations
show_profile_in_analysis_tab: true
profile_name: Mutations
profile_description: Somatic mutations from WES
data_filename: data_mutations_extended.maf
```

### data_mutations_extended.maf

Colonne minime richieste:

```
Hugo_Symbol	Entrez_Gene_Id	Center	NCBI_Build	Chromosome	Start_Position	End_Position	Strand	Variant_Classification	Variant_Type	Reference_Allele	Tumor_Seq_Allele1	Tumor_Seq_Allele2	Tumor_Sample_Barcode	Matched_Norm_Sample_Barcode	HGVSp_Short	t_depth	t_alt_count	n_depth	n_alt_count
EGFR	1956	OSR	GRCh38	7	55191822	55191822	+	Missense_Mutation	SNP	T	T	G	S001_T	S001_N	p.L858R	150	75	50	0
TP53	7157	OSR	GRCh38	17	7674220	7674220	+	Nonsense_Mutation	SNP	C	C	T	S001_T	S001_N	p.R273*	120	60	45	0
```

### case_lists/{study_id}_all.txt

```properties
cancer_study_identifier: lung_study_2024
stable_id: lung_study_2024_all
case_list_name: All samples
case_list_description: All samples (3 samples)
case_list_ids: S001_T	S001_N	S002_T
```

**Nota:** IDs separati da TAB, non spazi!

### case_lists/{study_id}_sequenced.txt

```properties
cancer_study_identifier: lung_study_2024
stable_id: lung_study_2024_sequenced
case_list_name: Samples with mutation data
case_list_description: Samples with mutation data (2 samples)
case_list_category: all_cases_with_mutation_data
case_list_ids: S001_T	S002_T
```

## Workflow Completo

### 1. Preparazione Dati

```bash
# Crea directory studio
mkdir -p lung_study_2024/case_lists

# Crea tutti i file usando i template sopra
cd lung_study_2024

# Verifica la struttura
tree .
```

### 2. Validazione Locale

```bash
# Copia studio nel container
sudo docker cp ~/lung_study_2024 cbioportal-container:/data/

# Valida
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    python3 validateData.py -s /data/lung_study_2024 -html /data/validation_report.html
"

# Copia report di validazione
sudo docker cp cbioportal-container:/data/validation_report.html /tmp/

# Apri in browser per vedere errori dettagliati
firefox /tmp/validation_report.html  # o chrome, safari, etc.
```

### 3. Correzione Errori

**Errori comuni e soluzioni:**

| Errore | Causa | Soluzione |
|--------|-------|-----------|
| Sample ID not found | ID campione nel MAF non in data_clinical_sample.txt | Allinea gli ID |
| Patient ID not found | ID paziente mancante | Aggiungi paziente in data_clinical_patient.txt |
| Missing required column | Colonna obbligatoria mancante nel MAF | Aggiungi colonna richiesta |
| Invalid chromosome | Cromosoma non valido (es. chr1 invece di 1) | Rimuovi prefisso "chr" |
| Duplicate case list stable_id | add_global_case_list in meta_study.txt | Rimuovi quella riga |

### 4. Caricamento

```bash
# Trova credenziali database
sudo docker exec cbioportal-database-container env | grep MYSQL

# Carica studio (usa IP e PORT corretti)
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    ./metaImport.py -s /data/lung_study_2024 -u http://172.21.91.6:8080 -o
"
```

**Opzioni metaImport.py:**
- `-s`: path allo studio
- `-u`: URL dell'istanza cBioPortal
- `-o`: override warnings (procedi anche con warning non critici)

### 5. Verifica Caricamento

```bash
# Controlla nel database
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e \
    "SELECT CANCER_STUDY_IDENTIFIER, NAME, STATUS FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='lung_study_2024';"

# Conta dati caricati
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e \
    "SELECT
        (SELECT COUNT(*) FROM patient WHERE CANCER_STUDY_ID=(SELECT CANCER_STUDY_ID FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='lung_study_2024')) as patients,
        (SELECT COUNT(*) FROM sample WHERE PATIENT_ID IN (SELECT PATIENT_ID FROM patient WHERE CANCER_STUDY_ID=(SELECT CANCER_STUDY_ID FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='lung_study_2024'))) as samples,
        (SELECT COUNT(*) FROM mutation WHERE GENETIC_PROFILE_ID IN (SELECT GENETIC_PROFILE_ID FROM genetic_profile WHERE CANCER_STUDY_ID=(SELECT CANCER_STUDY_ID FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='lung_study_2024'))) as mutations;"
```

### 6. Riavvio e Verifica Web

```bash
# Riavvia container
sudo docker restart cbioportal-container

# Attendi startup
sleep 120

# Verifica container attivo
sudo docker ps | grep cbioportal-container
```

Poi vai su **http://172.21.91.6:8080** e cerca il tuo studio.

## Validazione e Troubleshooting

### Warning Non Critici (OK con -o)

Questi warning sono normali e possono essere ignorati usando `-o`:

```
WARNING: data_clinical_patient.txt: Columns OS_MONTHS and/or OS_STATUS not found
WARNING: data_clinical_patient.txt: Columns DFS_MONTHS and/or DFS_STATUS not found
WARNING: data_mutations_extended.maf: SWISSPROT value is not a (single) UniProtKB/Swiss-Prot name
INFO: data_mutations_extended.maf: Line will not be loaded due to variant classification filter (Silent, Intron, etc.)
```

### Errori Critici (DEVONO essere risolti)

```
ERROR: Multiple case lists with this stable_id defined
→ Rimuovi add_global_case_list: true da meta_study.txt

ERROR: Sample identifier S001 in MAF file is not defined in clinical file
→ Aggiungi S001 in data_clinical_sample.txt

ERROR: Patient identifier P001 is not defined
→ Aggiungi P001 in data_clinical_patient.txt

ERROR: Required column 'Hugo_Symbol' not found in MAF
→ Aggiungi colonna mancante nel MAF
```

### Debug con Validation Report

Il report HTML (`/tmp/validation_report.html`) mostra:

- ✅ File validati correttamente (verde)
- ⚠️ Warning non bloccanti (giallo)
- ❌ Errori critici (rosso) con numero di riga e dettagli

Apri sempre il report per vedere i dettagli completi.

### Rimozione Studio (per ricaricare)

```bash
# Rimuovi studio dal database
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    ./cbioportalImporter.py -c remove-study -id lung_study_2024
"

# Riavvia
sudo docker restart cbioportal-container

# Ricarica con file corretti
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    ./metaImport.py -s /data/lung_study_2024 -u http://172.21.91.6:8080 -o
"
```

## Checklist Finale

### Prima di Validare

- [ ] Tutti i file meta hanno `cancer_study_identifier` corretto
- [ ] `meta_study.txt` NON ha `add_global_case_list: true`
- [ ] Case lists sono in subdirectory `case_lists/`
- [ ] IDs paziente consistenti in tutti i file
- [ ] IDs campione consistenti in tutti i file
- [ ] Tumor_Sample_Barcode nel MAF corrisponde a Sample IDs clinici
- [ ] Reference genome specificato (hg19/hg38)
- [ ] Case list IDs separati da TAB non spazi

### Dopo Validazione

- [ ] Validation report controllato
- [ ] Errori critici risolti
- [ ] Warning capiti (OS_MONTHS, SWISSPROT, etc. sono OK)

### Dopo Caricamento

- [ ] Studio presente nel database (query SQL)
- [ ] Numero pazienti corretto nel database
- [ ] Numero campioni corretto nel database
- [ ] Numero mutazioni corretto nel database
- [ ] Container riavviato
- [ ] Studio visibile in web UI
- [ ] Dati clinici visualizzati correttamente
- [ ] Mutazioni visualizzate correttamente

## Riferimenti Rapidi

### Comandi Essenziali

```bash
# Valida
sudo docker exec cbioportal-container bash -c "cd /cbioportal/core/src/main/scripts/importer && python3 validateData.py -s /data/STUDY_NAME -html /data/validation_report.html"

# Carica
sudo docker exec cbioportal-container bash -c "cd /cbioportal/core/src/main/scripts/importer && ./metaImport.py -s /data/STUDY_NAME -u http://IP:PORT -o"

# Lista studi
sudo docker exec cbioportal-database-container mysql -u cbio_user -pPASSWORD cbioportal -e 'SELECT CANCER_STUDY_IDENTIFIER, NAME FROM cancer_study;'

# Riavvia
sudo docker restart cbioportal-container
```

### Credenziali Database

**Locale (172.21.91.6):**
- User: `cbio_user`
- Password: `somepassword`
- Database: `cbioportal`

**Produzione INFN (131.154.26.79):**
- User: `cbio_user`
- Password: `P@ssword1`
- Database: `cbioportal`

### File Format Reference

**cBioPortal Docs:** https://docs.cbioportal.org/file-formats/

**MAF Specification:** https://docs.gdc.cancer.gov/Data/File_Formats/MAF_Format/

---

**Ultima modifica:** 2025-11-17  
**Basato su:** Esperienza caricamento melanoma_colo829_test su cBioPortal 4.1.13
