#!/bin/bash
set -euo pipefail

# nf-caveman test runner
# This script runs the pipeline with test data and validates the output

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "Running nf-caveman test suite"
echo "========================================="
echo ""

# Clean previous test runs
echo "Cleaning previous test results..."
rm -rf "${PROJECT_DIR}/test_results" "${PROJECT_DIR}/test_work"

# Run the pipeline with test profile
echo "Running pipeline with test profile..."
cd "${PROJECT_DIR}"

nextflow run main.nf \
    -profile test,docker \
    --outdir test_results \
    -work-dir test_work \
    -resume

# Check results
echo ""
echo "========================================="
echo "Validating test results"
echo "========================================="

ERRORS=0

# Check that results directory exists
if [ ! -d "test_results" ]; then
    echo "ERROR: Results directory not found"
    ((ERRORS++))
else
    echo "✓ Results directory exists"
fi

# List output files
echo ""
echo "Output files generated:"
find test_results -type f || echo "No files found"

# Check for VCF outputs
echo ""
VCF_COUNT=$(find test_results -type f \( -name "*.vcf.gz" -o -name "*.vcf" \) 2>/dev/null | wc -l)
if [ "$VCF_COUNT" -gt 0 ]; then
    echo "✓ Found ${VCF_COUNT} VCF file(s)"
    find test_results -type f \( -name "*.vcf.gz" -o -name "*.vcf" \)
else
    echo "WARNING: No VCF files found in output"
fi

# Check for index files
IDX_COUNT=$(find test_results -type f -name "*.tbi" 2>/dev/null | wc -l)
if [ "$IDX_COUNT" -gt 0 ]; then
    echo "✓ Found ${IDX_COUNT} index file(s)"
else
    echo "WARNING: No index files found"
fi

# Summary
echo ""
echo "========================================="
if [ $ERRORS -eq 0 ]; then
    echo "✓ All tests passed!"
    echo "========================================="
    exit 0
else
    echo "✗ ${ERRORS} error(s) found"
    echo "========================================="
    exit 1
fi
