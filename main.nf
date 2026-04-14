#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

// --- Parameter validation ---
def validModels = ['hac', 'sup']
if (!validModels.contains(params.model)) {
    error "Invalid --model '${params.model}'. Must be one of: ${validModels.join(', ')}"
}

if (!params.input) {
    error "Please provide --input <path>"
}

def inputPath = file(params.input)
if (!inputPath.exists()) {
    error "Input path does not exist: ${params.input}"
}

// --- Process ---
process DORADO_BASECALL {
    tag "${sample_id}"

    publishDir "${params.outdir}/${sample_id}", mode: 'copy'

    input:
    tuple val(sample_id), path(pod5_dir)

    output:
    tuple val(sample_id), path("${sample_id}.bam"),        emit: bam
    tuple val(sample_id), path("${sample_id}_dorado.log"), emit: log

    script:
    """
    dorado basecaller ${params.model} ${pod5_dir} \
        >  ${sample_id}.bam \
        2> ${sample_id}_dorado.log
    """
}

// --- Workflow ---
workflow {
    def subDirs = inputPath.listFiles().findAll { it.isDirectory() }

    def ch_input
    if (subDirs.size() > 0) {
        // Each subdirectory → separate parallel job
        ch_input = Channel.fromList(
            subDirs.collect { d -> tuple(d.name, d) }
        )
    } else {
        // Flat pod5 dir → single job, sample_id = directory basename
        ch_input = Channel.of( tuple(inputPath.name, inputPath) )
    }

    DORADO_BASECALL(ch_input)
}
