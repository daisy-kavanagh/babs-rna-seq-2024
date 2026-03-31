#!/usr/bin/env bash
set -euo pipefail

# Find abundance.tsv files one directory below the current directory
mapfile -t abundance_tsv < <(find . -mindepth 2 -maxdepth 2 -type f -name abundance.tsv | sort)

# Check that we found something
if [ "${#abundance_tsv[@]}" -eq 0 ]; then
    echo "Error: no abundance.tsv files found in subdirectories." >&2
    exit 1
fi

# Use the first file to get transcript IDs
first_abundance_tsv="${abundance_tsv[0]}"

# Extract transcript IDs from first file, skipping header
awk 'NR > 1 {print $1}' "$first_abundance_tsv" > .transcript_id.tsv

# Paste all abundance files side by side, skip header row,
# and extract column 4 of each 5-column block (= est_counts)
paste "${abundance_tsv[@]}" | \
awk 'NR > 1 {
    for (i = 4; i <= NF; i += 5) {
        printf "%s", $i
        if (i + 5 <= NF) {
            printf "\t"
        }
    }
    printf "\n"
}' > .counts_only.tsv

# Combine transcript IDs with counts
paste .transcript_id.tsv .counts_only.tsv > .transcript_counts_raw.tsv

# Build header from parent directory names of abundance.tsv files
header="transcripts"
for f in "${abundance_tsv[@]}"; do
    sample_name="$(basename "$(dirname "$f")")"
    header="${header},${sample_name}"
done

# Write final CSV
{
    echo "$header"
    awk 'BEGIN{OFS=","} {
        for (i = 1; i <= NF; i++) {
            printf "%s", $i
            if (i < NF) {
                printf ","
            }
        }
        printf "\n"
    }' .transcript_counts_raw.tsv
} > transcript_counts.csv

# Clean up
rm -f .transcript_id.tsv .counts_only.tsv .transcript_counts_raw.tsv
