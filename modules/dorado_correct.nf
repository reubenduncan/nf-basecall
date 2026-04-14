// NOTE: dorado correct (HERRO algorithm) has demanding resource requirements:
//   CPU  >= 64 cores recommended
//   RAM  >= 256 GB recommended
//   GPU  >= 32 GB VRAM recommended
//   Input reads must be >= 10 kbp and coverage >= 30x for best results.
// Adjust process resources in nextflow.config (withName: 'DORADO_CORRECT') as needed.
process DORADO_CORRECT {
    tag "${sample_id}"

    publishDir "${params.outdir}/${sample_id}", mode: 'copy'

    input:
    tuple val(sample_id), path(reads)

    output:
    tuple val(sample_id), path("${sample_id}_corrected.fasta"), emit: fasta
    tuple val(sample_id), path("${sample_id}_correct.log"),     emit: log

    script:
    def device_arg = params.device   ? "--device ${params.device}"     : ''
    def paf_arg    = params.paf_file ? "--from-paf ${params.paf_file}" : ''
    """
    dorado correct ${reads} \\
        ${device_arg} \\
        ${paf_arg} \\
        --threads ${task.cpus} \\
        > ${sample_id}_corrected.fasta \\
        2> ${sample_id}_correct.log
    """
}
