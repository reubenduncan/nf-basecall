# Define the path to your basecalling model and the main input directory
MODEL="sup"
INPUT_DIR="./pod5_pass"
OUTPUT_DIR="./fastq_pass"

# Create the output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Loop through each subdirectory in the input directory
for dir in "$INPUT_DIR"/barcode{04..24}/; do
    # Strip the trailing slash to get the barcode name
    BARCODE=$(basename "$dir")
    
    echo "Processing $BARCODE..."
    
    mkdir -p "$OUTPUT_DIR/$BARCODE"

    # Run Dorado
    # --device cuda:0 (use GPU)
    # "$dir" (the specific barcode folder)
    dorado basecaller "$MODEL" "$dir" > "$OUTPUT_DIR/${BARCODE}/${BARCODE}.bam" 2> "$OUTPUT_DIR/dorado.log"
done

echo "Basecalling complete."
