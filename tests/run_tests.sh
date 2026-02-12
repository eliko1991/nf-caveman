#!/bin/bash
# Comprehensive test script for nf-caveman
# Runs pipeline, checks outputs, and validates VCF contents

set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "nf-caveman Test Suite"
echo "========================================="

# Start timing
START_TIME=$SECONDS

# Step 1: Run Nextflow pipeline
echo -e "\n${YELLOW}Step 1: Running nf-caveman pipeline with test profile...${NC}"
nextflow run ${GITHUB_WORKSPACE:-$PWD} \
  -profile test,docker \
  --outdir ./results \
  -work-dir ./work \
  -resume

# Step 2: Check outputs exist
echo -e "\n${YELLOW}Step 2: Checking output files...${NC}"

# Check results directory
if [ ! -d "./results" ]; then
    echo -e "${RED}✗ Error: results directory not found${NC}"
    exit 1
fi
echo "✓ Results directory exists"

# Check for VCF files
vcf_count=$(find ./results -name "*.vcf.gz" -type f | wc -l)
echo "Found $vcf_count VCF file(s)"

if [ "$vcf_count" -eq 0 ]; then
    echo -e "${RED}✗ Error: No VCF files found in results${NC}"
    exit 1
fi
echo "✓ VCF files generated"

# Check for specific output file
output_vcf="./results/tumor_vs_normal.flagged.muts.vcf.gz"
if [ ! -f "$output_vcf" ]; then
    echo -e "${RED}✗ Error: Expected output file not found: $output_vcf${NC}"
    exit 1
fi
echo "✓ Expected output file exists: $output_vcf"

# Step 3: Validate VCF contents
echo -e "\n${YELLOW}Step 3: Validating VCF contents...${NC}"

expected_vcf="tests/data/expected_output/tumor_vs_normal.flagged.muts.vcf"
if [ ! -f "$expected_vcf" ]; then
    echo -e "${RED}✗ Error: Expected VCF file not found: $expected_vcf${NC}"
    exit 1
fi

python3 tests/validate_vcf.py "$expected_vcf" "$output_vcf"

# Calculate elapsed time
ELAPSED=$((SECONDS - START_TIME))
HOURS=$((ELAPSED / 3600))
MINUTES=$(((ELAPSED % 3600) / 60))
SECS=$((ELAPSED % 60))

# All tests passed
echo -e "\n${GREEN}=========================================${NC}"
echo -e "${GREEN}✓ All tests passed!${NC}"
printf "${GREEN}Elapsed Time: %02d:%02d:%02d${NC}\n" $HOURS $MINUTES $SECS
echo -e "${GREEN}=========================================${NC}"
exit 0
