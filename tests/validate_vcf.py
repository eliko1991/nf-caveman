#!/usr/bin/env python3
"""
VCF validation script for nf-caveman tests.
Compares expected and actual VCF files to verify correct variant detection.
"""

import sys
import gzip
from typing import Set, Tuple


def read_vcf_variants(vcf_path: str) -> Set[Tuple[str, str, str, str]]:
    """
    Read variants from VCF file (handles both .vcf and .vcf.gz).

    Returns set of tuples: (CHROM, POS, REF, ALT)
    """
    variants = set()

    # Determine if file is gzipped
    open_func = gzip.open if vcf_path.endswith('.gz') else open
    mode = 'rt' if vcf_path.endswith('.gz') else 'r'

    with open_func(vcf_path, mode) as f:
        for line in f:
            # Skip header lines
            if line.startswith('#'):
                continue

            # Parse variant line
            fields = line.strip().split('\t')
            if len(fields) < 5:
                continue

            chrom = fields[0]
            pos = fields[1]
            ref = fields[3]
            alt = fields[4]

            variants.add((chrom, pos, ref, alt))

    return variants


def main():
    if len(sys.argv) != 3:
        print("Usage: validate_vcf.py <expected.vcf> <actual.vcf[.gz]>")
        sys.exit(1)

    expected_vcf = sys.argv[1]
    actual_vcf = sys.argv[2]

    print("Comparing VCFs...")
    print(f"  Expected: {expected_vcf}")
    print(f"  Actual:   {actual_vcf}")

    # Read variants from both files
    try:
        expected_variants = read_vcf_variants(expected_vcf)
        actual_variants = read_vcf_variants(actual_vcf)
    except FileNotFoundError as e:
        print(f"✗ Error: {e}")
        sys.exit(1)
    except Exception as e:
        print(f"✗ Error reading VCF files: {e}")
        sys.exit(1)

    # Compare variant counts
    print(f"\nVariant counts:")
    print(f"  Expected: {len(expected_variants)}")
    print(f"  Actual:   {len(actual_variants)}")

    # Find differences
    missing_variants = expected_variants - actual_variants
    extra_variants = actual_variants - expected_variants

    # Report results
    success = True

    if missing_variants:
        print(f"\n✗ Found {len(missing_variants)} missing variant(s):")
        for chrom, pos, ref, alt in sorted(missing_variants):
            print(f"  Missing: {chrom}:{pos} {ref}>{alt}")
        success = False
    else:
        print(f"\n✓ All {len(expected_variants)} expected variants found")

    if extra_variants:
        print(f"\n✗ Found {len(extra_variants)} extra variant(s):")
        for chrom, pos, ref, alt in sorted(extra_variants):
            print(f"  Extra: {chrom}:{pos} {ref}>{alt}")
        success = False
    else:
        print("✓ No extra variants detected")

    if success:
        print("\n✓ VCF validation passed!")
        sys.exit(0)
    else:
        print("\n✗ VCF validation failed!")
        sys.exit(1)


if __name__ == "__main__":
    main()
