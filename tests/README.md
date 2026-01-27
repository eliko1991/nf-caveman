# nf-caveman Tests

This directory contains test data and scripts for the nf-caveman pipeline.

## Test Data

The test data in `tests/data/` is derived from the [toil_caveman](https://github.com/papaemmelab/toil_caveman) repository and includes:

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

## Test Profiles

- **test** - Minimal test with small dataset (suitable for CI)
- **test_full** - Full test with larger dataset (optional, for comprehensive testing)

## Comparing with toil_caveman

The nf-caveman pipeline should produce equivalent results to toil_caveman when given the same inputs. Key outputs to compare:

- VCF files with somatic variants
- Flagged mutations
- SNP calls

## Adding New Tests

1. Add test data to `tests/data/`
2. Create a new config profile in `conf/`
3. Update the CI workflow in `.github/workflows/ci.yml`
4. Document expected outputs
