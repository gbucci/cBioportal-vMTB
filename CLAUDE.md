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
