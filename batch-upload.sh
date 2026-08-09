#!/bin/bash
set -euo pipefail

DIR="$1"
LABEL="${2:-batch}"
BATCH_MB="${3:-50}"
EXT="${4:-mp4}"
MB=$((BATCH_MB * 1024 * 1024))

FILES=()
while IFS= read -r f; do FILES+=("$f"); done < <(find "$DIR" -name "*.$EXT" -type f | sort)
CUR=()
CUR_SIZE=0
N=0
TOTAL_BYTES=0

size() {
  stat -f%z "$1"
}

push_batch() {
  N=$((N + 1))
  echo "=== $LABEL batch $N: ${#CUR[@]} files, $((CUR_SIZE / 1024 / 1024))MB ==="
  git add "${CUR[@]}"
  git commit -q -m "Add ${LABEL} exercise ${EXT} (batch $N)"
  until git push -q origin main; do
    echo "push failed, retrying in 5s..."
    sleep 5
  done
  CUR=()
  CUR_SIZE=0
}

for f in "${FILES[@]}"; do
  S=$(size "$f")
  TOTAL_BYTES=$((TOTAL_BYTES + S))
  if (( CUR_SIZE + S > MB )) && (( ${#CUR[@]} > 0 )); then
    push_batch
  fi
  CUR+=("$f")
  CUR_SIZE=$((CUR_SIZE + S))
done

if (( ${#CUR[@]} > 0 )); then
  push_batch
fi

echo "=== Done: $N batches, $((TOTAL_BYTES / 1024 / 1024))MB total ==="
