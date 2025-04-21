#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Imports
include { filterReadQuality; bamToFastq } from '../../../modules/input_processing'


workflow {

    test_bam = Channel.fromPath(params.test_bam, checkIfExists: true)
    
    bamToFastq(test_bam)
    fastq = bamToFastq.out.fastq
    fastq.view { "FASTQ created from BAM: ${it.getName()}" }

    fastq_filtered = filterReadQuality(fastq)
    fastq_filtered.view { "FASTQ filtered: ${it.getName()}" }
}