# Studio cBioPortal: Melanoma COLO-829 Test Case

## Descrizione
Studio di test per il caso di melanoma COLO-829 con:
- Mutazione BRAF V600E 
- Resistenza acquisita a vemurafenib
- Delezione PTEN

## Contenuto
- 1 paziente (C_UFLEBTVLHO)
- 2 campioni (COLO-829 tumore, COLO-829BL normale)
- 36 mutazioni somatiche

## Caricamento su cBioPortal

### 1. Validazione (opzionale)
```bash
docker exec -it cbioportal-container bash
cd /cbioportal/core/src/main/scripts/importer
python3 validateData.py -s /data/melanoma_colo829_test -html /data/validation_report.html
```

### 2. Caricamento
```bash
docker exec -it cbioportal-container bash
cd /cbioportal/core/src/main/scripts/importer
./metaImport.py -s /data/melanoma_colo829_test
```

### 3. Riavvio container (per vedere lo studio)
```bash
docker restart cbioportal-container
```

## Note
- Genome di riferimento: hg38/GRCh38
- Dati da linea cellulare COLO-829 (NYGC)
- Link pubblicazione: https://pubmed.ncbi.nlm.nih.gov/32913971/

Generato il: 2025-11-17 10:26:44
