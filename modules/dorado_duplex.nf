process DORADO_DUPLEX {
    tag "${sample_id}"

    publishDir "${params.outdir}/${sample_id}", mode: 'copy'

    input:
    tuple val(sample_id), path(pod5_dir)

    output:
    tuple val(sample_id), path("${sample_id}.bam"),        emit: bam
    tuple val(sample_id), path("${sample_id}_dorado.log"), emit: log

    script:
    def mod_arg    = params.modified_bases ? "--modified-bases ${params.modified_bases}" : ''
    def ref_arg    = params.reference      ? "--reference ${params.reference}"           : ''
    def qscore_arg = params.min_qscore > 0 ? "--min-qscore ${params.min_qscore}"        : ''
    def device_arg = params.device         ? "--device ${params.device}"                : ''
    def batch_arg  = "--batchsize ${params.batchsize}"
    def pairs_arg  = params.pairs_file     ? "--pairs ${params.pairs_file}"             : ''
    def recursive  = params.recursive      ? '--recursive'                              : ''
    def models_dir = params.models_directory ? "--models-directory ${params.models_directory}" : ''
    """
    dorado duplex \\
        ${params.model} \\
        ${pod5_dir} \\
        ${recursive} \\
        ${mod_arg} \\
        ${ref_arg} \\
        ${qscore_arg} \\
        ${device_arg} \\
        ${batch_arg} \\
        ${pairs_arg} \\
        ${models_dir} \\
        > ${sample_id}.bam \\
        2> ${sample_id}_dorado.log
    """
}
