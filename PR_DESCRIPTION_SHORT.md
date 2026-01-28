## Summary

Adds CI testing infrastructure to nf-caveman using test data from [toil_caveman](https://github.com/papaemmelab/toil_caveman).

## What's Changed

### GitHub Actions CI
- **Lint job**: Validates Nextflow config
- **Test job**: Runs pipeline with test data using Docker
- Triggers on push/PR to main, gcpslurm, or develop branches

### Test Data
Minimal test dataset from toil_caveman (chromosomal subset):
- Tumor/normal BAM files + indices
- Reference genome + indices
- Flagging and annotation files

### Container Fix
Fixed all modules to use Docker by default with automatic Singularity fallback:
```nextflow
container workflow.containerEngine == 'singularity' ?
    '/isabl/local/nf-caveman//papaemmelab_docker_cgp_v1_1.sif' :
    'papaemmelab/docker-cgp:v1.1'
```

### Test Infrastructure
- `tests/run_tests.sh` - Comprehensive test runner (pipeline + validation)
- `tests/validate_vcf.py` - VCF content validation script
- `tests/README.md` - Documentation
- Updated `conf/test.config` with test data paths
- Added `.gitignore` and CI badge

## Testing

```bash
# Run tests locally
./tests/run_tests.sh

# Or with Nextflow
nextflow run main.nf -profile test,docker --outdir test_results
```

## Files Changed
- 47 files changed: 3,167 additions, 36 deletions
- 10 modules updated with container specs
- 31 test data files added
