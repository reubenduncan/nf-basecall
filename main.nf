#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { DORADO_BASECALL } from './modules/dorado_basecall'
include { DORADO_DUPLEX   } from './modules/dorado_duplex'
include { DORADO_DEMUX    } from './modules/dorado_demux'
include { DORADO_SUMMARY  } from './modules/dorado_summary'
include { DORADO_CORRECT  } from './modules/dorado_correct'

// ---------------------------------------------------------------------------
// Parameter validation
// ---------------------------------------------------------------------------

if (!params.input) {
    error "Please provide --input <path>"
}

def inputPath = file(params.input)
if (!inputPath.exists()) {
    error "Input path does not exist: ${params.input}"
}

// Model: accept shorthand names or full versioned names (contain '@')
def validModels = ['fast', 'hac', 'sup']
if (!params.model.contains('@') && !validModels.contains(params.model)) {
    error "Invalid --model '${params.model}'. " +
          "Use 'fast', 'hac', 'sup', or a full model name (e.g. dna_r10.4.1_e8.2_400bps_hac@v5.0.0)"
}

// Trim mode
def validTrim = ['adapters', 'all', 'none']
if (params.trim && !validTrim.contains(params.trim)) {
    error "Invalid --trim '${params.trim}'. Must be one of: ${validTrim.join(', ')}"
}

// Mutual exclusions
if (params.duplex && params.correct) {
    error "--duplex and --correct cannot be used together"
}

def outputFormats = [params.emit_fastq, params.emit_sam, params.emit_cram].count { it }
if (outputFormats > 1) {
    error "Only one output format flag may be set: --emit_fastq, --emit_sam, or --emit_cram"
}

// Optional file paths
if (params.reference && !file(params.reference).exists()) {
    error "Reference file does not exist: ${params.reference}"
}
if (params.bed_file && !file(params.bed_file).exists()) {
    error "BED file does not exist: ${params.bed_file}"
}
if (params.pairs_file && !file(params.pairs_file).exists()) {
    error "Pairs file does not exist: ${params.pairs_file}"
}
if (params.read_ids && !file(params.read_ids).exists()) {
    error "Read IDs file does not exist: ${params.read_ids}"
}
if (params.paf_file && !file(params.paf_file).exists()) {
    error "PAF file does not exist: ${params.paf_file}"
}

// ---------------------------------------------------------------------------
// Workflow
// ---------------------------------------------------------------------------

workflow {

    // Auto-detect input structure:
    //   - subdirectories present → one parallel job per subdir (e.g. per-barcode layout)
    //   - flat directory of POD5 files → single job, sample_id = directory name
    def subDirs = inputPath.listFiles().findAll { it.isDirectory() }

    def ch_input
    if (subDirs.size() > 0) {
        ch_input = Channel.fromList(
            subDirs.collect { d -> tuple(d.name, d) }
        )
    } else {
        ch_input = Channel.of( tuple(inputPath.name, inputPath) )
    }

    // ------------------------------------------------------------------
    // Basecalling — simplex (default) or duplex
    // ------------------------------------------------------------------
    def ch_reads
    if (params.duplex) {
        DORADO_DUPLEX(ch_input)
        ch_reads = DORADO_DUPLEX.out.bam
    } else {
        DORADO_BASECALL(ch_input)
        ch_reads = DORADO_BASECALL.out.reads
    }

    // ------------------------------------------------------------------
    // Summary — always generated for BAM output
    // ------------------------------------------------------------------
    def is_bam = !params.emit_fastq && !params.emit_sam && !params.emit_cram
    if (is_bam) {
        DORADO_SUMMARY(ch_reads)
    }

    // ------------------------------------------------------------------
    // Barcode demultiplexing — split classified BAM into per-barcode files.
    // The basecaller writes a single BAM with BC tags when --kit-name is
    // provided; DORADO_DEMUX splits it and sorts each output BAM.
    // Only applicable when output is BAM (not FASTQ/SAM/CRAM).
    // ------------------------------------------------------------------
    if (params.kit_name && is_bam) {
        DORADO_DEMUX(ch_reads)
    }

    // ------------------------------------------------------------------
    // Error correction (optional, high resource requirements)
    // ------------------------------------------------------------------
    if (params.correct) {
        DORADO_CORRECT(ch_reads)
    }
}
