process DORADO_SUMMARY {
    tag "${sample_id}"

    publishDir "${params.outdir}/${sample_id}", mode: 'copy'

    input:
    tuple val(sample_id), path(bam)

    output:
    tuple val(sample_id), path("${sample_id}_summary.tsv"), emit: summary

    script:
    """
    dorado summary ${bam} > ${sample_id}_summary.tsv
    """
}
