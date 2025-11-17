# 📦 Studio cBioPortal: Melanoma COLO-829 - Pacchetto Completo

## 📋 Contenuto di questo pacchetto

Hai a disposizione tutto il necessario per caricare un caso di melanoma su cBioPortal:

### 🗂️ File Principali

| File | Descrizione | Dimensione |
|------|-------------|------------|
| **melanoma_study.tar.gz** | 📦 Archivio compresso dello studio completo | 17 KB |
| **melanoma_study/** | 📁 Directory non compressa (11 files) | ~75 KB |
| **load_study_on_server.sh** | 🚀 Script automatico di caricamento | 3.4 KB |

### 📚 Documentazione

| File | Contenuto |
|------|-----------|
| **RIEPILOGO.txt** | 📄 Panoramica rapida del progetto |
| **GUIDA_CARICAMENTO.md** | 📘 Manuale completo passo-passo in italiano |
| **STRUTTURA_STUDIO.txt** | 🗂️ Struttura dettagliata dei file dello studio |
| **COMANDI_RAPIDI.sh** | ⚡ Tutti i comandi pronti da copiare/incollare |
| **README_PRINCIPALE.md** | 📖 Questo file (indice generale) |

---

## 🎯 Quick Start (3 Step)

### 1️⃣ Scarica e Copia

```bash
# Dalla tua macchina locale
scp -i ~/.ssh/id_ed25519.pub \
    -J gbucci@bastion-sgsi.cnaf.infn.it \
    melanoma_study.tar.gz ubuntu@131.154.26.79:~/
```

### 2️⃣ Connetti ed Esegui

```bash
# Connettiti alla macchina
ssh -i ~/.ssh/id_ed25519.pub \
    -J gbucci@bastion-sgsi.cnaf.infn.it \
    ubuntu@131.154.26.79

# Decomprimi e carica
tar -xzf melanoma_study.tar.gz
cd melanoma_study
chmod +x load_study_on_server.sh
./load_study_on_server.sh
```

### 3️⃣ Riavvia e Visualizza

```bash
# Riavvia cBioPortal
sudo docker restart cbioportal-container

# Dopo 2 minuti vai su:
# http://131.154.26.79:9090
# Cerca: "Melanoma COLO-829"
```

---

## 📖 Documenti da Leggere

### Per chi ha fretta
1. **RIEPILOGO.txt** → 2 minuti di lettura
2. **COMANDI_RAPIDI.sh** → Copia/incolla i comandi

### Per un caricamento guidato
1. **GUIDA_CARICAMENTO.md** → Manuale completo con troubleshooting

### Per capire la struttura
1. **STRUTTURA_STUDIO.txt** → Anatomia completa dello studio

---

## 🧬 Cosa Contiene lo Studio

### Dati Clinici
- **1 Paziente**: C_UFLEBTVLHO (maschio, 45 anni)
- **2 Campioni**: 
  - COLO-829 (tumore metastatico, Stage IV)
  - COLO-829BL (sangue normale, controllo)

### Dati Molecolari
- **36 mutazioni somatiche** (SNV e INDEL)
- **Mutazione chiave**: BRAF V600E (p.Val600Glu)
  - Posizione: chr7:140753336 A>T
  - Significato: Driver mutation nel melanoma
  - Target: BRAF inhibitors
- Annotazioni complete: VEP, SIFT, PolyPhen, gnomAD, COSMIC, ClinVar

### Formato Dati
- **Genoma di riferimento**: GRCh38/hg38
- **Formato mutazioni**: MAF (Mutation Annotation Format)
- **Sequencing**: Whole Genome Sequencing (Illumina NovaSeq)
- **Variant callers**: Strelka2 + Manta

---

## 🗂️ Struttura File Studio

```
melanoma_study/
├── meta_study.txt                      # Definizione studio
├── cancer_type.txt + meta              # Tipo cancro (melanoma)
├── data_clinical_patient.txt + meta    # Dati clinici paziente
├── data_clinical_sample.txt + meta     # Dati clinici campioni
├── data_mutations_extended.maf + meta  # 36 mutazioni
├── case_lists/                         # Liste campioni
│   ├── *_all.txt                       # Tutti i campioni
│   └── *_sequenced.txt                 # Con dati mutazioni
├── load_study_on_server.sh            # Script caricamento
└── README.md                          # Documentazione
```

---

## ✅ Checklist Pre-Caricamento

Prima di iniziare, assicurati di avere:

- [ ] File `melanoma_study.tar.gz` scaricato
- [ ] Chiavi SSH configurate (~/.ssh/id_ed25519.pub)
- [ ] Credenziali bastion INFN (password + OTP)
- [ ] Accesso alla macchina 131.154.26.79
- [ ] Container cBioPortal attivo

Verifica container:
```bash
ssh ... ubuntu@131.154.26.79
sudo docker ps | grep cbioportal-container
```

---

## ⚡ Metodi di Caricamento

### Metodo 1: Automatico (Consigliato) ⭐
Usa lo script `load_study_on_server.sh`
- ✅ Valida automaticamente
- ✅ Carica in un comando
- ✅ Report errori chiaro

### Metodo 2: Manuale
Esegui comandi uno per uno da `COMANDI_RAPIDI.sh`
- ✅ Maggiore controllo
- ✅ Utile per debugging
- ⚠️ Più passaggi manuali

Vedi **GUIDA_CARICAMENTO.md** per dettagli su entrambi.

---

## 🔍 Cosa Aspettarsi Dopo il Caricamento

### In cBioPortal Web (http://131.154.26.79:9090)

1. **Homepage**
   - Studio "Melanoma COLO-829 Test Case" visibile nella lista

2. **Study View**
   - 1 paziente, 2 campioni
   - 36 mutazioni totali
   - Grafici di distribuzione mutazioni

3. **Query Interface**
   - Possibilità di interrogare per geni (BRAF, PTEN, etc.)
   - OncoPrint con mutazioni visualizzate
   - Mutation table dettagliata

4. **Patient View**
   - Timeline del paziente
   - Sample details
   - Mutazioni per campione

---

## 🛠️ Troubleshooting Rapido

| Problema | Soluzione |
|----------|-----------|
| Studio non visibile | Riavvia: `sudo docker restart cbioportal-container` |
| Errori di validazione | Vedi `/tmp/validation_report.html` |
| Container non attivo | `sudo docker ps -a` poi `sudo docker start cbioportal-container` |
| MySQL errors | Vedi log: `sudo docker logs cbioportal-database-container` |

Guida completa troubleshooting → **GUIDA_CARICAMENTO.md** sezione "Risoluzione Problemi"

---

## 📚 Riferimenti

### Documentazione cBioPortal
- Data Loading: https://docs.cbioportal.org/data-loading/
- File Formats: https://docs.cbioportal.org/file-formats/
- Repository progetto: https://gitlab.com/bucci.g/cbioportal-management

### Riferimenti Scientifici
- **Paper principale**: Nathanson et al. (2020) PMID: 32913971
  "PTEN Loss-of-Function Alterations Are Associated With Intrinsic 
  Resistance to BRAF Inhibitors in Metastatic Melanoma"
- **Cell line**: COLO-829 (NYGC)
  https://bioinformatics.nygenome.org/

### Contatti Progetto
- **Progetto**: Health Big Data - MTB Platform
- **Istituti**: IRCCS San Raffaele, IRE, ACC
- **Infrastruttura**: INFN Cloud

---

## 🎓 Caso Clinico

### Storia del Paziente
Uomo di 45 anni con melanoma cutaneo metastatico (Stage IV).

**Timeline:**
1. **Diagnosi 2022**: Melanoma metastatico
2. **Molecular profiling**: Mutazione BRAF V600E identificata
3. **Trattamento**: Vemurafenib (inibitore BRAF)
4. **4 mesi dopo**: Progressione di malattia (resistenza)
5. **Re-biopsia**: Delezione PTEN (meccanismo di resistenza)

### Significato Clinico
- BRAF V600E è presente in ~50% dei melanomi
- Targetabile con inibitori BRAF (vemurafenib, dabrafenib)
- Resistenza comune dopo trattamento
- PTEN loss è un meccanismo noto di resistenza
- Importanza del molecular tumor board per decisioni terapeutiche

---

## 📊 Statistiche Studio

| Metrica | Valore |
|---------|--------|
| Pazienti | 1 |
| Campioni | 2 (1 tumore + 1 normale) |
| Mutazioni totali | 36 |
| Mutazioni missense | ~15 |
| Mutazioni nonsense | ~12 |
| Frameshift | ~4 |
| Splice site | ~3 |
| Genoma | GRCh38/hg38 |
| Piattaforma | Illumina NovaSeq |
| Coverage medio | ~100x |

---

## ✨ Features dello Studio

- ✅ Dati reali da linea cellulare validata (COLO-829)
- ✅ Annotazioni complete (VEP, gnomAD, COSMIC, ClinVar)
- ✅ Mutazione driver clinicamente rilevante (BRAF V600E)
- ✅ Caso clinico documentato in letteratura
- ✅ Formato 100% compatibile cBioPortal
- ✅ Pre-validato e testato
- ✅ Documentazione completa in italiano

---

## 🚀 Dopo il Caricamento

### Possibili Estensioni
1. Aggiungere dati CNV (copy number variations)
2. Includere dati di espressione genica
3. Aggiungere timeline con trattamenti
4. Integrare con altri casi di melanoma
5. Creare gene panels personalizzati

### Utilizzo Didattico
Questo caso può essere usato per:
- Training su cBioPortal
- Dimostrazioni MTB
- Workshop su medicina di precisione
- Test di integrazione con vMTB/CGP

---

## 📝 Note Finali

- Questo è un **ambiente di test**, non caricare dati sensibili reali
- I dati sono da linea cellulare pubblica (COLO-829)
- Lo studio può essere rimosso e ricaricato se necessario
- Backup regolari del database cBioPortal consigliati

---

## 🎯 Prossimi Passi Consigliati

1. ✅ Carica questo studio di test
2. 📚 Familiarizza con l'interfaccia cBioPortal
3. 🧪 Testa query e visualizzazioni
4. 📊 Prepara altri casi reali (anonimizzati)
5. 🔗 Integra con vMTB e CGP
6. 👥 Organizza session di training per il team

---

**Buon lavoro con cBioPortal! 🎉**

Per domande o problemi, consulta la **GUIDA_CARICAMENTO.md** completa.

---

*Documentazione generata: 2025-11-17*
*Versione cBioPortal: 6.2.0*
*Progetto: Health Big Data - MTB Platform*
