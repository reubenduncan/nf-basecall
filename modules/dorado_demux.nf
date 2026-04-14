process DORADO_DEMUX {
    tag "${sample_id}"

    publishDir "${params.outdir}/${sample_id}/demux", mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("demux_out/*.bam"),                      emit: bams,    optional: true
    tuple val(sample_id), path("demux_out/*.fastq"),                    emit: fastqs,  optional: true
    tuple val(sample_id), path("demux_out/sequencing_summary.txt"),     emit: summary, optional: true

    script:
    def fastq_arg     = params.emit_fastq         ? '--emit-fastq'        : ''
    def both_ends_arg = params.barcode_both_ends   ? '--barcode-both-ends' : ''
    """
    mkdir -p demux_out
    dorado demux ${reads} \\
        --kit-name ${params.kit_name} \\
        --output-dir demux_out \\
        ${fastq_arg} \\
        ${both_ends_arg} \\
        --sort-bam \\
        --emit-summary \\
        --threads ${task.cpus}
    """
}
