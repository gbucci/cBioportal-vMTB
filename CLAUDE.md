# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains a cBioPortal study package for a melanoma COLO-829 test case. The project is part of the Health Big Data - MTB (Molecular Tumor Board) Platform initiative involving IRCCS San Raffaele, IRE, and ACC institutions, running on INFN Cloud infrastructure.

**Key Purpose**: Provide a complete, validated study dataset for loading into cBioPortal to support molecular tumor board decision-making and precision medicine workflows.

## Study Data Structure

The study contains clinical and genomic data for a single melanoma patient with BRAF V600E mutation and acquired resistance to BRAF inhibitors:

- **Study ID**: `melanoma_colo829_test`
- **Patient**: C_UFLEBTVLHO (male, 45 years old, diagnosed 2022)
- **Samples**:
  - COLO-829 (metastatic tumor, Stage IV)
  - COLO-829BL (normal blood control)
- **Mutations**: 36 somatic mutations including the key driver mutation BRAF V600E (p.Val600Glu)
- **Reference Genome**: GRCh38/hg38
- **Platform**: Illumina NovaSeq, Whole Genome Sequencing
- **Variant Callers**: Strelka2 + Manta

## File Organization

### Core Study Files
```
melanoma_study/
├── meta_study.txt                      # Study metadata (ID, name, reference genome)
├── cancer_type.txt + meta              # Cancer type definition (melanoma)
├── data_clinical_patient.txt + meta    # Patient clinical data
├── data_clinical_sample.txt + meta     # Sample clinical data
├── data_mutations_extended.maf + meta  # MAF file with 36 mutations + VEP annotations
├── case_lists/                         # Sample cohort definitions
│   ├── *_all.txt                       # All samples (2)
│   └── *_sequenced.txt                 # Samples with mutation data (1)
└── README.md                           # Study documentation
```

### Documentation Files
- **README_PRINCIPALE.md**: Main documentation index with quickstart, file descriptions, and clinical case details
- **GUIDA_CARICAMENTO.md**: Complete step-by-step loading guide in Italian with troubleshooting
- **STRUTTURA_STUDIO.txt**: Detailed study file structure with mutation annotations breakdown
- **RIEPILOGO.txt**: Quick summary of what's included
- **COMANDI_RAPIDI.sh**: Copy-paste ready commands for all operations

### Deployment Files
- **load_study_on_server.sh**: Automated loading script for cBioPortal server
- **melanoma_study.tar.gz**: Compressed archive of complete study (17 KB)

## Common Commands

### Data Loading Workflow

**Prerequisites**: Access to cBioPortal server at 131.154.26.79 via INFN bastion host

#### 1. Transfer Study to Server
```bash
# From local machine via bastion jump host
scp -i ~/.ssh/id_ed25519.pub \
    -o ProxyJump=gbucci@bastion-sgsi.cnaf.infn.it \
    melanoma_study.tar.gz ubuntu@131.154.26.79:~/
```

#### 2. Connect to Server
```bash
ssh -i ~/.ssh/id_ed25519.pub \
    -J gbucci@bastion-sgsi.cnaf.infn.it \
    ubuntu@131.154.26.79
```

#### 3. Deploy Study (Automated Method)
```bash
# On cBioPortal server
cd ~
tar -xzf melanoma_study.tar.gz
cd melanoma_study
chmod +x load_study_on_server.sh
./load_study_on_server.sh
```

The script performs:
- Container health verification
- File copying to Docker container
- Study validation (with HTML report generation)
- Import to cBioPortal database

#### 4. Restart and Verify
```bash
# Restart container to reflect new study
sudo docker restart cbioportal-container

# Wait for startup (approximately 2 minutes)
sleep 120

# Access web interface at http://131.154.26.79:9090
# Search for "Melanoma COLO-829"
```

### Manual Loading Commands

For granular control over the loading process:

```bash
# Copy study to container
sudo docker cp ~/melanoma_study cbioportal-container:/data/

# Validate study
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    python3 validateData.py -s /data/melanoma_study -html /data/validation_report.html
"

# Copy validation report
sudo docker cp cbioportal-container:/data/validation_report.html /tmp/

# Import study
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    ./metaImport.py -s /data/melanoma_study
"

# Restart container
sudo docker restart cbioportal-container
```

### Troubleshooting Commands

```bash
# Check container status
sudo docker ps | grep cbioportal-container

# View cBioPortal logs
sudo docker logs -f cbioportal-container

# View MySQL database logs
sudo docker logs cbioportal-database-container

# List all loaded studies
sudo docker exec cbioportal-container bash -c "
    mysql -u cbio_user -pP@ssword1 cbioportal -e \
    'SELECT CANCER_STUDY_IDENTIFIER, NAME FROM cancer_study;'
"

# Verify specific study in database
sudo docker exec cbioportal-container bash -c "
    mysql -u cbio_user -pP@ssword1 cbioportal -e \
    'SELECT * FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER=\"melanoma_colo829_test\";'
"

# Count loaded mutations for study
sudo docker exec cbioportal-container bash -c "
    mysql -u cbio_user -pP@ssword1 cbioportal -e \
    'SELECT COUNT(*) FROM mutation WHERE GENETIC_PROFILE_ID IN
    (SELECT GENETIC_PROFILE_ID FROM genetic_profile WHERE CANCER_STUDY_ID =
    (SELECT CANCER_STUDY_ID FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER=\"melanoma_colo829_test\"));'
"

# Remove study (for reloading)
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    ./cbioportalImporter.py -c remove-study -id melanoma_colo829_test
"
```

## Architecture and Data Standards

### cBioPortal Data Format Requirements

All files must conform to cBioPortal specifications:

1. **Meta Files**: Define data type, profile ID, and file associations
2. **Clinical Data**: Must have 4-line headers with attribute metadata
3. **MAF Files**: Require specific columns (Hugo_Symbol, Chromosome, Start_Position, End_Position, Reference_Allele, Tumor_Seq_Allele2, Variant_Classification, etc.)
4. **Sample/Patient ID Consistency**: IDs must match across all files
5. **Case Lists**: Define sample cohorts with stable_id format: `{study_id}_{list_type}`

### MAF File Annotations

The `data_mutations_extended.maf` includes comprehensive annotations:
- **VEP** (Variant Effect Predictor) annotations
- **SIFT/PolyPhen** pathogenicity scores
- **gnomAD** population frequencies
- **COSMIC** mutation database IDs
- **ClinVar** clinical significance
- **Protein domain** mappings (PDB)
- **Read depth** metrics (tumor/normal coverage)

## Infrastructure Details

### cBioPortal Environment
- **Version**: 6.2.0
- **Database**: MySQL 8.0
- **Session Service**: 0.6.1
- **Containers**:
  - `cbioportal-container` (web application, port 9090)
  - `cbioportal-database-container` (MySQL, port 3306)
  - `cbioportal-session-container`

### Server Access
- **Host**: 131.154.26.79
- **Bastion**: gbucci@bastion-sgsi.cnaf.infn.it
- **Authentication**: SSH key + INFN password + OTP
- **Web UI**: http://131.154.26.79:9090

### Database Credentials
- **Database**: `cbioportal`
- **User**: `cbio_user`
- **Password**: `P@ssword1`

## Clinical Case Context

This dataset represents a clinically relevant melanoma case demonstrating:

1. **Initial Diagnosis**: Metastatic melanoma with BRAF V600E mutation (present in ~50% of melanomas)
2. **Treatment**: Vemurafenib (BRAF inhibitor therapy)
3. **Resistance**: Disease progression after 4 months due to PTEN loss
4. **MTB Relevance**: Illustrates importance of molecular profiling and resistance mechanisms

**Scientific Reference**: Nathanson et al. (2020) PMID: 32913971
"PTEN Loss-of-Function Alterations Are Associated With Intrinsic Resistance to BRAF Inhibitors in Metastatic Melanoma"

**Data Source**: COLO-829 cell line from New York Genome Center (NYGC)

## Important Notes

- This is a **test environment** - do not load sensitive patient data
- Data originates from publicly available COLO-829 cell line
- Study can be safely removed and reloaded for testing purposes
- Always validate study before loading using `validateData.py`
- Container restart required after loading for changes to appear in web UI
- Validation reports saved to `/tmp/validation_report.html` for debugging

## Local Development Environment

### Local cBioPortal Setup

For local development/testing (e.g., 172.21.91.6:8080, cBioPortal 4.1.13):

**Container Architecture:**
- `cbioportal-container`: Web application (port 8080)
- `cbioportal-database-container`: MySQL 5.7 (port 3306)

**Database Credentials (Local):**
- Database: `cbioportal`
- User: `cbio_user`
- Password: `somepassword` (check with `sudo docker exec cbioportal-database-container env | grep MYSQL`)

### Loading Studies on Local Environment

```bash
# 1. Clone repository
git clone https://github.com/gbucci/cBioportal-vMTB.git
cd cBioportal-vMTB

# 2. Extract study
tar -xzf melanoma_study.tar.gz

# 3. Copy to home directory (script expects it there)
cp -r melanoma_study ~/

# 4. Load using local script
cd melanoma_study
./load_study_on_local.sh
```

**Important:** The script uses `$HOME/melanoma_study` by default. Always ensure you copy the latest version there before loading.

### Manual Local Loading (with correct credentials)

```bash
# Find database credentials
sudo docker exec cbioportal-database-container env | grep MYSQL

# Copy study to container
sudo docker cp ~/melanoma_study cbioportal-container:/data/

# Validate (standalone)
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    python3 validateData.py -s /data/melanoma_study -html /data/validation_report.html
"

# Import with portal URL and override warnings
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    ./metaImport.py -s /data/melanoma_study -u http://YOUR_IP:8080 -o
"

# Restart and verify
sudo docker restart cbioportal-container
sleep 120
```

### Verify Study in Database

```bash
# List all studies (use correct credentials)
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e \
    'SELECT CANCER_STUDY_IDENTIFIER, NAME FROM cancer_study;'

# Count mutations for specific study
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e \
    "SELECT COUNT(*) as mutation_count FROM mutation WHERE GENETIC_PROFILE_ID IN
    (SELECT GENETIC_PROFILE_ID FROM genetic_profile WHERE CANCER_STUDY_ID =
    (SELECT CANCER_STUDY_ID FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='melanoma_colo829_test'));"
```

## Common Pitfalls and Solutions

### 1. Duplicate Case List Error

**Error:**
```
ERROR: Multiple case lists with this stable_id defined in the study
```

**Cause:** `add_global_case_list: true` in `meta_study.txt` creates automatic case lists that conflict with manual ones.

**Solution:** Remove `add_global_case_list: true` from `meta_study.txt` and use only manual case lists in `case_lists/` directory.

### 2. Case Lists Not in Subdirectory

**Error:** Case list files in root directory instead of `case_lists/`

**Solution:** Ensure proper structure:
```
study_name/
├── case_lists/
│   ├── study_id_all.txt
│   └── study_id_sequenced.txt
└── (other files)
```

### 3. Wrong Study Directory Loaded

**Issue:** Script loads old cached version from `$HOME/melanoma_study` instead of updated git version.

**Solution:**
```bash
# Remove old version
rm -rf $HOME/melanoma_study

# Copy fresh version
cp -r ~/cBioportal-vMTB/melanoma_study $HOME/

# Or specify directory explicitly
STUDY_DIR="/path/to/correct/study" ./load_study_on_local.sh
```

### 4. metaImport Connection Refused

**Error:**
```
ConnectionRefusedError: [Errno 111] Connection refused
```

**Cause:** metaImport.py trying to connect to cBioPortal API at wrong URL.

**Solution:** Always specify portal URL with `-u` flag:
```bash
./metaImport.py -s /data/study_name -u http://YOUR_IP:PORT -o
```

### 5. Validation Warnings Block Import

**Issue:** Import stops due to non-critical warnings (OS_MONTHS, SWISSPROT format, etc.)

**Solution:** Use `-o` (override) flag to proceed:
```bash
./metaImport.py -s /data/study_name -u http://YOUR_IP:PORT -o
```

### 6. Study Not Visible in Web UI After Successful Import

**Cause:** The `GROUPS` field in the `cancer_study` table is empty. Studies must have `GROUPS = 'PUBLIC'` to be visible in the web interface.

**Root Cause:** Missing `groups: PUBLIC` field in `meta_study.txt`.

**Correct Solution (Recommended):**

Add `groups: PUBLIC` to your `meta_study.txt` file:

```
type_of_cancer: [cancer_type_id]
cancer_study_identifier: [study_id]
name: [Study Display Name]
description: [Study description]
citation: [Reference or data source]
pmid: [PubMed ID if applicable]
reference_genome: hg38
groups: PUBLIC
```

Then remove and reload the study:

```bash
# Remove old study
sudo docker exec cbioportal-container bash -c "
    cd /core/scripts/importer && \
    python3 cbioportalImporter.py -c remove-study -id [study_id]
"

# Reload with correct configuration
sudo docker compose exec cbioportal bin/bash
cd core/scripts/
./dumpPortalInfo.pl /portalinfodump/
cd ../..
metaImport.py -p /portalinfodump/ -s /data/[study_name]/ -o
exit

# Restart container
sudo docker restart cbioportal-container
```

**Alternative (Database Fix):**

If you can't reload the study, fix the database directly:

```bash
# Check GROUPS field (note: GROUPS is a MySQL reserved keyword, use backticks)
sudo docker exec cbioportal-database-container mysql -u cbio_user -pPASSWORD cbioportal -e "
SELECT CANCER_STUDY_IDENTIFIER, NAME, \`GROUPS\`, PUBLIC, STATUS
FROM cancer_study
WHERE CANCER_STUDY_IDENTIFIER='[study_id]';
"

# Fix GROUPS field (IMPORTANT: use backticks around GROUPS - it's a reserved keyword!)
sudo docker exec cbioportal-database-container mysql -u cbio_user -pPASSWORD cbioportal -e "
UPDATE cancer_study
SET \`GROUPS\` = 'PUBLIC'
WHERE CANCER_STUDY_IDENTIFIER='[study_id]';
"

# Restart container to refresh cache
sudo docker restart cbioportal-container
sleep 120  # Wait for startup
```

**Prevention:** Always include `groups: PUBLIC` in `meta_study.txt` before importing.

## Creating New Studies - Best Practices

### Pre-Flight Checklist

Before creating a new study, ensure you have:

- [ ] Study ID (lowercase, no spaces, e.g., `lung_study_2024`)
- [ ] Cancer type defined (or use existing from cancer_type.txt)
- [ ] Patient/Sample IDs consistent across all files
- [ ] MAF file with required columns (Hugo_Symbol, Chromosome, etc.)
- [ ] Clinical data with 4-line headers
- [ ] Reference genome specified (hg19/hg38)

### Required File Structure

```
study_name/
├── meta_study.txt                      # NO add_global_case_list!
├── meta_cancer_type.txt
├── cancer_type.txt                     # If new cancer type
├── meta_clinical_patient.txt
├── data_clinical_patient.txt
├── meta_clinical_sample.txt
├── data_clinical_sample.txt
├── meta_mutations_extended.txt
├── data_mutations_extended.maf
├── case_lists/
│   ├── {study_id}_all.txt
│   └── {study_id}_sequenced.txt
└── README.md
```

### meta_study.txt Template

```
type_of_cancer: [cancer_type_id]
cancer_study_identifier: [study_id]
name: [Study Display Name]
description: [Study description]
citation: [Reference or data source]
pmid: [PubMed ID if applicable]
reference_genome: hg38
groups: PUBLIC
```

**CRITICAL:**
- Do NOT include `add_global_case_list: true` - it causes duplicate case list errors
- **ALWAYS include `groups: PUBLIC`** - without this, the study won't be visible in the web interface

### Case List Templates

**{study_id}_all.txt:**
```
cancer_study_identifier: [study_id]
stable_id: [study_id]_all
case_list_name: All samples
case_list_description: All samples ([N] samples)
case_list_ids: SAMPLE1	SAMPLE2	SAMPLE3
```

**{study_id}_sequenced.txt:**
```
cancer_study_identifier: [study_id]
stable_id: [study_id]_sequenced
case_list_name: Samples with mutation data
case_list_description: Samples with mutation data ([N] samples)
case_list_category: all_cases_with_mutation_data
case_list_ids: SAMPLE1	SAMPLE2
```

### Validation Workflow

```bash
# 1. Validate locally before loading
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    python3 validateData.py -s /data/study_name -html /data/validation_report.html
"

# 2. Check validation report
sudo docker cp cbioportal-container:/data/validation_report.html /tmp/
# Open in browser to see detailed errors

# 3. Fix errors, then re-validate

# 4. Load only when validation passes
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    ./metaImport.py -s /data/study_name -u http://IP:PORT -o
"
```

### Expected Warnings (Non-Critical)

These warnings are normal and can be overridden with `-o`:

- `OS_MONTHS and/or OS_STATUS not found` - Overall survival data optional
- `DFS_MONTHS and/or DFS_STATUS not found` - Disease-free survival optional
- `SWISSPROT value is not a (single) UniProtKB/Swiss-Prot name` - Will auto-resolve
- Mutations filtered (Silent, Intron, 5'Flank, etc.) - Expected behavior

### Post-Load Verification

```bash
# 1. Check study in database
sudo docker exec cbioportal-database-container mysql -u cbio_user -p[PASSWORD] cbioportal -e \
    "SELECT CANCER_STUDY_IDENTIFIER, NAME, STATUS FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='[study_id]';"

# 2. Count loaded data
sudo docker exec cbioportal-database-container mysql -u cbio_user -p[PASSWORD] cbioportal -e \
    "SELECT
        (SELECT COUNT(*) FROM patient WHERE CANCER_STUDY_ID=(SELECT CANCER_STUDY_ID FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='[study_id]')) as patients,
        (SELECT COUNT(*) FROM sample WHERE PATIENT_ID IN (SELECT PATIENT_ID FROM patient WHERE CANCER_STUDY_ID=(SELECT CANCER_STUDY_ID FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='[study_id]'))) as samples,
        (SELECT COUNT(*) FROM mutation WHERE GENETIC_PROFILE_ID IN (SELECT GENETIC_PROFILE_ID FROM genetic_profile WHERE CANCER_STUDY_ID=(SELECT CANCER_STUDY_ID FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER='[study_id]'))) as mutations;"

# 3. Restart container
sudo docker restart cbioportal-container

# 4. Verify in web UI
# Navigate to http://IP:PORT and search for study name
```

### Study Removal (for reloading)

```bash
# Remove study from database
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    ./cbioportalImporter.py -c remove-study -id [study_id]
"

# Then reload with corrected files
```

## Quick Reference

### Environment-Specific Details

| Aspect | Production (INFN) | Local Dev |
|--------|------------------|-----------|
| cBioPortal Version | 6.2.0 | 4.1.13 |
| MySQL Version | 8.0 | 5.7 |
| Web Port | 9090 | 8080 |
| Host | 131.154.26.79 | 172.21.91.6 |
| DB Password | P@ssword1 | somepassword |
| Access | Via bastion | Direct |

### Most Common Commands

```bash
# Validate study
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    python3 validateData.py -s /data/STUDY_NAME -html /data/validation_report.html"

# Load study (local)
sudo docker exec cbioportal-container bash -c "
    cd /cbioportal/core/src/main/scripts/importer && \
    ./metaImport.py -s /data/STUDY_NAME -u http://IP:PORT -o"

# List studies
sudo docker exec cbioportal-database-container mysql -u cbio_user -pPASSWORD cbioportal -e \
    'SELECT CANCER_STUDY_IDENTIFIER, NAME FROM cancer_study;'

# Restart
sudo docker restart cbioportal-container
```
