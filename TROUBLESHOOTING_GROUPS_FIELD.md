# Troubleshooting: Study Not Visible in cBioPortal Web Interface

## Problem

The `melanoma_colo829_test` study was successfully imported into the cBioPortal database but is not visible in the web interface at http://131.154.26.79:9090.

## Root Cause

The `GROUPS` field in the `cancer_study` table is empty. For studies to be visible in the web portal, this field must be set to `'PUBLIC'`.

### Database Comparison

**Working study (lgg_ucsf_2014):**
```
GROUPS: PUBLIC
STATUS: 1
PUBLIC: 1
```

**Our study (melanoma_colo829_test):**
```
GROUPS: (empty)
STATUS: 1
PUBLIC: 1
```

## Solution

### Option 1: Automated Script (Recommended)

On the remote server (ubuntu@131.154.26.79), transfer and run the fix script:

```bash
# Transfer script to remote server
scp -i ~/.ssh/id_ed25519.pub \
    -o ProxyJump=gbucci@bastion-sgsi.cnaf.infn.it \
    fix_groups_field.sh ubuntu@131.154.26.79:~/

# SSH to server
ssh -i ~/.ssh/id_ed25519.pub \
    -J gbucci@bastion-sgsi.cnaf.infn.it \
    ubuntu@131.154.26.79

# Run fix script
chmod +x fix_groups_field.sh
./fix_groups_field.sh
```

### Option 2: Manual Commands

Run these commands on the remote server:

#### Step 1: Update GROUPS field

**IMPORTANT:** The `GROUPS` keyword must be escaped with backticks because it's a MySQL reserved keyword.

```bash
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "
UPDATE cancer_study
SET \`GROUPS\` = 'PUBLIC'
WHERE CANCER_STUDY_IDENTIFIER = 'melanoma_colo829_test';
"
```

#### Step 2: Verify the update

```bash
sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "
SELECT CANCER_STUDY_IDENTIFIER, NAME, \`GROUPS\`, PUBLIC, STATUS
FROM cancer_study
WHERE CANCER_STUDY_IDENTIFIER = 'melanoma_colo829_test';
"
```

Expected output:
```
+----------------------------+-----------------------------+--------+--------+--------+
| CANCER_STUDY_IDENTIFIER    | NAME                        | GROUPS | PUBLIC | STATUS |
+----------------------------+-----------------------------+--------+--------+--------+
| melanoma_colo829_test      | Melanoma COLO-829 Test Case | PUBLIC |      1 |      1 |
+----------------------------+-----------------------------+--------+--------+--------+
```

#### Step 3: Restart cBioPortal container

```bash
sudo docker restart cbioportal-container
```

#### Step 4: Wait for startup

```bash
# Wait approximately 2 minutes for cBioPortal to fully start
sleep 120
```

#### Step 5: Verify in web interface

1. Open browser to: http://131.154.26.79:9090
2. Search for "Melanoma COLO-829" in the study selector
3. The study should now appear and be accessible

## Why This Happened

The `metaImport.py` script successfully imported the study data (patients, samples, mutations) but did not properly set the `GROUPS` field. This field controls which user groups can access the study in the web interface.

## Technical Details

### MySQL Reserved Keyword Issue

The initial UPDATE attempt failed with:
```
ERROR 1064 (42000): You have an error in your SQL syntax near 'GROUPS = 'PUBLIC''
```

This is because `GROUPS` is a reserved keyword in MySQL and must be escaped with backticks (\`GROUPS\`).

### Database Schema

The `cancer_study` table structure:
- `CANCER_STUDY_ID`: Unique identifier (10 for our study)
- `CANCER_STUDY_IDENTIFIER`: Study ID string ('melanoma_colo829_test')
- `GROUPS`: User groups with access (should be 'PUBLIC')
- `PUBLIC`: Boolean flag (1 = public, 0 = private)
- `STATUS`: Study status (0 = deleted, 1 = available)

### Related Tables

Successfully populated by import:
- `patient`: 1 patient (C_UFLEBTVLHO)
- `sample`: 2 samples (COLO-829, COLO-829BL)
- `mutation`: 33 mutations including BRAF V600E
- `genetic_profile`: Mutation profile metadata
- `mutation_event`: Unique mutation events

## Prevention for Future Imports

To avoid this issue when importing future studies:

1. **Always verify GROUPS field after import:**
   ```bash
   sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "
   SELECT CANCER_STUDY_IDENTIFIER, \`GROUPS\`, PUBLIC, STATUS
   FROM cancer_study
   WHERE CANCER_STUDY_IDENTIFIER = 'YOUR_STUDY_ID';
   "
   ```

2. **Fix immediately if empty:**
   ```bash
   sudo docker exec cbioportal-database-container mysql -u cbio_user -psomepassword cbioportal -e "
   UPDATE cancer_study
   SET \`GROUPS\` = 'PUBLIC'
   WHERE CANCER_STUDY_IDENTIFIER = 'YOUR_STUDY_ID';
   "
   ```

3. **Always restart container after database modifications:**
   ```bash
   sudo docker restart cbioportal-container
   ```

## References

- MySQL Reserved Keywords: https://dev.mysql.com/doc/refman/8.0/en/keywords.html
- cBioPortal Import Documentation: https://docs.cbioportal.org/deployment/import/
- cBioPortal Database Schema: https://docs.cbioportal.org/deployment/architecture-overview/#database-schema

## Contact

For issues related to:
- **cBioPortal deployment**: Check Docker container logs with `sudo docker logs cbioportal-container`
- **Database issues**: Verify MySQL container status with `sudo docker ps`
- **Study data**: Review validation report in `/tmp/validation_report.html`
