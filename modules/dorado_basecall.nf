process DORADO_BASECALL {
    tag "${sample_id}"

    publishDir "${params.outdir}/${sample_id}", mode: 'copy'

    input:
    tuple val(sample_id), path(pod5_dir)

    output:
    tuple val(sample_id), path("${sample_id}.${params.emit_fastq ? 'fastq' : (params.emit_sam ? 'sam' : (params.emit_cram ? 'cram' : 'bam'))}"), emit: reads
    tuple val(sample_id), path("${sample_id}_dorado.log"), emit: log

    script:
    def ext           = params.emit_fastq ? 'fastq' : (params.emit_sam ? 'sam' : (params.emit_cram ? 'cram' : 'bam'))
    def mod_arg       = params.modified_bases       ? "--modified-bases ${params.modified_bases}"                       : ''
    def ref_arg       = params.reference            ? "--reference ${params.reference}"                                 : ''
    def bed_arg       = params.bed_file             ? "--bed-file ${params.bed_file}"                                   : ''
    def mm2_arg       = params.mm2_opts             ? "--mm2-opts \"${params.mm2_opts}\""                               : ''
    def qscore_arg    = params.min_qscore > 0       ? "--min-qscore ${params.min_qscore}"                              : ''
    def fastq_arg     = params.emit_fastq           ? '--emit-fastq'                                                    : ''
    def sam_arg       = params.emit_sam             ? '--emit-sam'                                                      : ''
    def cram_arg      = params.emit_cram            ? '--emit-cram'                                                     : ''
    def moves_arg     = params.emit_moves           ? '--emit-moves'                                                    : ''
    def summary_arg   = params.emit_summary         ? '--emit-summary'                                                  : ''
    def poly_a_arg    = params.estimate_poly_a      ? '--estimate-poly-a'                                               : ''
    def kit_arg       = params.kit_name             ? "--kit-name ${params.kit_name}"                                   : ''
    def both_ends_arg = params.barcode_both_ends    ? '--barcode-both-ends'                                             : ''
    def barr_arg      = params.barcode_arrangement  ? "--barcode-arrangement ${params.barcode_arrangement}"             : ''
    def bseq_arg      = params.barcode_sequences    ? "--barcode-sequences ${params.barcode_sequences}"                 : ''
    // When kit_name is set, preserve barcodes with --no-trim so DORADO_DEMUX can split later.
    // Also honour explicit params.no_trim. Otherwise apply the configured --trim mode.
    def trim_arg      = (params.no_trim || params.kit_name) ? '--no-trim' : "--trim ${params.trim}"
    def device_arg    = params.device               ? "--device ${params.device}"                                       : ''
    def batch_arg     = "--batchsize ${params.batchsize}"
    def chunk_arg     = params.chunksize            ? "--chunksize ${params.chunksize}"                                 : ''
    def overlap_arg   = params.overlap              ? "--overlap ${params.overlap}"                                     : ''
    def runners_arg   = params.num_runners          ? "--num-runners ${params.num_runners}"                             : ''
    def resume_arg    = params.resume_from          ? "--resume-from ${params.resume_from}"                             : ''
    def read_ids_arg  = params.read_ids             ? "--read-ids ${params.read_ids}"                                   : ''
    def max_reads_arg = params.max_reads            ? "--max-reads ${params.max_reads}"                                 : ''
    def recursive_arg = params.recursive            ? '--recursive'                                                     : ''
    def models_dir    = params.models_directory     ? "--models-directory ${params.models_directory}"                   : ''
    """
    dorado basecaller \\
        ${params.model} \\
        ${pod5_dir} \\
        ${recursive_arg} \\
        ${mod_arg} \\
        ${ref_arg} \\
        ${bed_arg} \\
        ${mm2_arg} \\
        ${qscore_arg} \\
        ${fastq_arg} \\
        ${sam_arg} \\
        ${cram_arg} \\
        ${moves_arg} \\
        ${summary_arg} \\
        ${poly_a_arg} \\
        ${kit_arg} \\
        ${both_ends_arg} \\
        ${barr_arg} \\
        ${bseq_arg} \\
        ${trim_arg} \\
        ${device_arg} \\
        ${batch_arg} \\
        ${chunk_arg} \\
        ${overlap_arg} \\
        ${runners_arg} \\
        ${resume_arg} \\
        ${read_ids_arg} \\
        ${max_reads_arg} \\
        ${models_dir} \\
        > ${sample_id}.${ext} \\
        2> ${sample_id}_dorado.log
    """
}
