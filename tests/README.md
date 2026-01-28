# nf-caveman Tests

This directory contains test data and scripts for the nf-caveman pipeline.

## Test Data

The test data located in `tests/data/` includes:

- **tumor/** - Tumor BAM file and index
- **normal/** - Normal BAM file and index
- **reference/** - Reference genome FASTA and indices
- **flagging/** - Optional flagging BED files
- **annotable_region/** - Optional annotation files

This is a minimal test dataset suitable for CI testing.

## Running Tests

### Using the test script

```bash
./tests/run_test.sh
```

### Manually with Nextflow

```bash
nextflow run main.nf -profile test,docker --outdir test_results
```

### In CI

Tests run automatically via GitHub Actions on push/PR to main, gcpslurm, or develop branches.

## Test Results

The nf-caveman pipeline produces minimal results:
- VCF files with somatic variants
- Flagged mutations
- SNP calls

## Adding New Tests

1. Add test data to `tests/data/`
2. Create a new config profile in `conf/`, if needed.
3. Update the CI workflow in `.github/workflows/ci.yml`
4. Document expected outputs
