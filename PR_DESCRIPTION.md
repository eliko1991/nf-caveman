# Pull Request: Add CI Testing with GitHub Actions

## Summary

This PR adds comprehensive CI testing infrastructure to the nf-caveman pipeline, using test data ported from the original [toil_caveman](https://github.com/papaemmelab/toil_caveman) repository.

## Motivation

The nf-caveman pipeline is a refactoring of toil_caveman using Nextflow, but it lacks proper automated testing. This PR addresses that gap by:

1. Setting up GitHub Actions for continuous integration
2. Importing test data from toil_caveman for validation
3. Ensuring the pipeline can be tested automatically on every commit/PR

## Changes

### 1. GitHub Actions CI Workflow (`.github/workflows/ci.yml`)

Added automated testing with two jobs:

- **Lint Job**: Validates Nextflow configuration
  - Installs Nextflow and nf-core tools
  - Runs config validation

- **Test Job**: Runs the full pipeline with test data
  - Uses Docker for containerization
  - Runs with minimal test dataset
  - Validates output files (VCF files)
  - Uploads results as artifacts for debugging

The workflow triggers on:
- Push to `main`, `gcpslurm`, or `develop` branches
- Pull requests to these branches

### 2. Test Data (`tests/data/`)

Copied from toil_caveman repository:

```
tests/data/
├── tumor/              # Tumor BAM files + indices
├── normal/             # Normal BAM files + indices
├── reference/          # Reference genome FASTA + indices
├── flagging/           # Flagging BED files and configs
└── annotable_region/   # Annotation files
```

This is a minimal test dataset (chromosomal subset) suitable for CI validation without excessive runtime.

### 3. Container Configuration Fix

**Problem**: All module files had Docker containers commented out and were hardcoded to use a local Singularity path.

**Solution**: Updated all 10 module files to use Docker by default with conditional Singularity support:

```nextflow
container workflow.containerEngine == 'singularity' ?
    '/isabl/local/nf-caveman//papaemmelab_docker_cgp_v1_1.sif' :
    'papaemmelab/docker-cgp:v1.1'
```

**Benefits**:
- Works with Docker out of the box (CI, local development)
- Automatically switches to Singularity when using the `singularity` or `gcp_slurm` profile
- No more hardcoded paths breaking the pipeline for other users

### 4. Test Infrastructure

- **`tests/run_test.sh`**: Local test runner script
  - Runs the pipeline with test profile
  - Validates output files
  - Provides clear pass/fail feedback

- **`tests/README.md`**: Documentation for tests
  - Explains test data structure
  - Instructions for running tests locally and in CI
  - Guidance for adding new tests

- **`conf/test.config`**: Updated test configuration
  - Points to the test data files
  - Sets resource limits suitable for CI (2 CPUs, 6GB RAM)

### 5. Additional Files

- **`.gitignore`**: Ignore Nextflow work directories, results, and logs
- **`README.md`**: Added CI badge to show build status

## Testing

### Local Testing

```bash
# Run with the test script
./tests/run_test.sh

# Or manually with Nextflow
nextflow run main.nf -profile test,docker --outdir test_results
```

### CI Testing

GitHub Actions will automatically run tests on every push and pull request. Results will be visible in the Actions tab.

## Files Changed

**Modified** (12 files):
- `README.md` - Added CI badge
- `conf/test.config` - Updated with test data paths
- All 10 module files in `modules/local/` - Fixed container specifications

**Added** (35 files):
- `.github/workflows/ci.yml` - CI workflow
- `.gitignore` - Ignore patterns
- `tests/run_test.sh` - Test runner
- `tests/README.md` - Test documentation
- 31 test data files in `tests/data/`

## Migration from toil_caveman

This PR maintains compatibility with toil_caveman:
- Uses the same test data
- Expects similar outputs (VCF files with somatic variants)
- Validates that the Nextflow refactoring produces correct results

## Next Steps

After merging:
1. Monitor CI runs to ensure stability
2. Consider adding integration tests for different input types
3. Add test for the full pipeline with flagging enabled
4. Set up code coverage reporting (if applicable)

## Checklist

- [x] Added GitHub Actions workflow
- [x] Copied test data from toil_caveman
- [x] Fixed Docker/Singularity container specifications
- [x] Created test runner script
- [x] Added documentation
- [x] Updated .gitignore
- [x] Added CI badge to README
- [ ] Verified tests pass in CI (pending collaborator access to push)
- [ ] Reviewed by maintainer

## Related Issues

This PR addresses the need for automated testing mentioned in discussions about migrating from toil_caveman to Nextflow.

---

**Branch**: `add-testing`
**Base**: `gcpslurm`
