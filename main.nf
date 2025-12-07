#!/usr/bin/env nextflow

params.mode = params.mode ?: null
params.input_reference = params.input_reference ?: "data/reference.fasta"
params.input_reads = params.input_reads ?: "data/reads.fasta"
params.output_mapping = params.output_mapping ?: "results/output.txt"
params.output_contigs = params.output_contigs ?: "results/output_contigs.fasta"


// validate mode
if (!params.mode) {
    error "Missing required parameter: --mode. Must be 'mapper' or 'assembler'."
}

if ( params.mode != 'mapper' && params.mode != 'assembler' ) {
    throw new IllegalArgumentException("Invalid mode: ${params.mode}. Allowed values: mapper, assembler")
}

// helper channels
mapper_pair_ch = Channel.of([ params.input_reference, params.input_reads ])
assembler_reads_ch = Channel.of(params.input_reads)

// Mapper process
process RUN_MAPPER {
    tag "mapper"

    input:
    val pair from mapper_pair_ch

    output:
    path "${params.output_mapping}"

    script:
    """
    mkdir -p \$(dirname "${params.output_mapping}")
    python3 mapper.py ${pair[0]} ${pair[1]} ${params.output_mapping}
    """
}

// Assembler process
process RUN_ASSEMBLER {
    tag "assembler"

    input:
    val reads from assembler_reads_ch

    output:
    path "${params.output_contigs}"

    script:
    """
    mkdir -p \$(dirname "${params.output_contigs}")
    ./assembly ${reads} ${params.output_contigs}
    """
}


workflow {
    if ( params.mode == 'mapper' ) {
        RUN_MAPPER()
    } else {
        RUN_ASSEMBLER()
    }
}


if ( params.help ) {
    log.info """
    Usage:
      nextflow run main.nf --mode mapper --input_reads reads.fasta --input_reference ref.fasta

    Parameters:
      --mode              mapper|assembler
      --input_reads       FASTA
      --input_reference   FASTA
      --output_mapping    TXT
      --output_contigs    FASTA
    """
    exit 0
}
