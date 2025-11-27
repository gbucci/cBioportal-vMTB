# Next Steps: Fix melanoma_colo829_test Visibility Issue

## Problem Summary

The `melanoma_colo829_test` study was successfully imported into the cBioPortal database but is **not visible** in the web interface at http://131.154.26.79:9090.

**Root Cause:** The `GROUPS` field in the `cancer_study` table is empty. It should be set to `'PUBLIC'` for the study to appear in the portal.

## Solution Ready

I've created the following files to fix this issue:

### 1. `fix_groups_field.sh` - Automated Fix Script
Complete automated solution that:
- Updates the GROUPS field to 'PUBLIC'
- Verifies the update
- Restarts the cBioPortal container
- Waits for startup

### 2. `TROUBLESHOOTING_GROUPS_FIELD.md` - Detailed Documentation
Comprehensive guide including:
- Problem diagnosis steps
- Root cause explanation
- Manual fix commands
- Prevention strategies for future imports
- Technical details about MySQL reserved keywords

### 3. Updated `CLAUDE.md`
Added this issue as "Common Pitfall #6" for future reference.

## What You Need to Do

### Option 1: Use the Automated Script (Recommended)

**On your local machine:**
```bash
# Transfer the fix script to the remote server
cd /home/user/cBioportal-vMTB

scp -i ~/.ssh/id_ed25519.pub \
    -o ProxyJump=gbucci@bastion-sgsi.cnaf.infn.it \
    fix_groups_field.sh ubuntu@131.154.26.79:~/
```

**On the remote server (ubuntu@131.154.26.79):**
```bash
# Make executable and run
chmod +x fix_groups_field.sh
./fix_groups_field.sh
```

The script will automatically:
1. Update the GROUPS field
2. Verify the change
3. Restart the container
4. Wait for cBioPortal to start

### Option 2: Manual Commands

If you prefer to run commands manually, SSH to the remote server and execute:

```bash
# 1. Update GROUPS field (note the backticks around GROUPS!)
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "
UPDATE cancer_study
SET \`GROUPS\` = 'PUBLIC'
WHERE CANCER_STUDY_IDENTIFIER = 'melanoma_colo829_test';
"

# 2. Verify the update
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "
SELECT CANCER_STUDY_IDENTIFIER, NAME, \`GROUPS\`, PUBLIC, STATUS
FROM cancer_study
WHERE CANCER_STUDY_IDENTIFIER = 'melanoma_colo829_test';
"

# You should see:
# GROUPS: PUBLIC
# PUBLIC: 1
# STATUS: 1

# 3. Restart container
sudo docker restart cbioportal-container

# 4. Wait for startup (approximately 2 minutes)
sleep 120
```

### Option 3: Copy-Paste Single Command

```bash
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "UPDATE cancer_study SET \`GROUPS\` = 'PUBLIC' WHERE CANCER_STUDY_IDENTIFIER = 'melanoma_colo829_test';" && sudo docker restart cbioportal-container
```

## Verification

After running the fix, verify the study appears in the web interface:

1. Open browser to: http://131.154.26.79:9090
2. Click on the study selector dropdown (top navigation)
3. Search for "Melanoma" or "COLO-829"
4. The study should now appear: **"Melanoma COLO-829 Test Case"**
5. Select it to view the study dashboard

You should see:
- 1 patient (C_UFLEBTVLHO)
- 2 samples (COLO-829 tumor, COLO-829BL normal)
- 33 mutations including BRAF V600E

## Technical Details

### Why Did This Happen?

The `metaImport.py` script with portal info dump (`-p` flag) successfully imported all study data but failed to set the `GROUPS` field. This is a known quirk of the import process when using `-p` instead of `-u` for authentication.

### Why Use Backticks?

`GROUPS` is a MySQL reserved keyword (like SELECT, UPDATE, WHERE, etc.). To use it as a column name in SQL queries, it must be escaped with backticks:

```sql
-- WRONG (syntax error):
UPDATE cancer_study SET GROUPS = 'PUBLIC' ...

-- CORRECT (with backticks):
UPDATE cancer_study SET `GROUPS` = 'PUBLIC' ...
```

### Database State Before Fix

```
mysql> SELECT * FROM cancer_study WHERE CANCER_STUDY_IDENTIFIER = 'melanoma_colo829_test'\G
*************************** 1. row ***************************
CANCER_STUDY_ID: 10
CANCER_STUDY_IDENTIFIER: melanoma_colo829_test
TYPE_OF_CANCER_ID: mel
NAME: Melanoma COLO-829 Test Case
DESCRIPTION: Metastatic melanoma with BRAF V600E mutation and acquired resistance
GROUPS:                    # ← EMPTY! This is the problem
PUBLIC: 1
PMID: 32913971
CITATION: Nathanson et al. (2020)
STATUS: 1                  # ← 1 = AVAILABLE
IMPORT_DATE: 2025-11-27 14:32:45
```

All other data is correct - patients, samples, mutations are all loaded. Only the `GROUPS` field needs to be fixed.

## Prevention for Future Studies

After importing any study, always run this verification:

```bash
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "
SELECT CANCER_STUDY_IDENTIFIER, \`GROUPS\`, PUBLIC, STATUS
FROM cancer_study
WHERE CANCER_STUDY_IDENTIFIER = 'YOUR_STUDY_ID';
"
```

If `GROUPS` is empty, immediately fix it:

```bash
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "
UPDATE cancer_study SET \`GROUPS\` = 'PUBLIC' WHERE CANCER_STUDY_IDENTIFIER = 'YOUR_STUDY_ID';
"
```

## Git Changes Committed

All documentation has been committed to the repository:

```
Commit: f28c1ae
Branch: claude/cbioportal-study-generator-01GyaH91VchePQLX61gGNMm7

Files added/updated:
  - fix_groups_field.sh (new, executable)
  - TROUBLESHOOTING_GROUPS_FIELD.md (new)
  - CLAUDE.md (updated with pitfall #6)
```

Changes have been pushed to GitHub and are ready for review.

## Summary

You're **one command away** from making the study visible in cBioPortal!

The study data is already in the database. You just need to fix one database field and restart the container.

Recommended action:
1. Transfer `fix_groups_field.sh` to the remote server
2. Run it
3. Access http://131.154.26.79:9090 and enjoy your study!

---

**Questions?** Refer to:
- `TROUBLESHOOTING_GROUPS_FIELD.md` for detailed explanations
- `CLAUDE.md` section "Common Pitfalls #6" for quick reference
- cBioPortal documentation: https://docs.cbioportal.org/
