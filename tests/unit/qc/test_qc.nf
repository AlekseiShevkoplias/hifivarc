#!/usr/bin/env nextflow

nextflow.enable.dsl=2

// Imports
include { seqkitStats; nanoplot; fastqc; multiqc } from '../../../modules/qc'


workflow {
    fastq = Channel.fromPath(params.test_fastq, checkIfExists: true)
    
    stats_dir = seqkitStats(fastq).stats_dir
    stats_dir.view { "SeqKit stats created: ${it.getName()}" }
    
    nanoplot_dir = nanoplot(fastq).nanoplot_dir
    nanoplot_dir.view { "nanoplot figures created: ${it.getName()}" }

    fastqc_dir = fastqc(fastq).fastqc_dir
    fastqc_dir.view { "fastqc results created: ${it.getName()}" }

    report_dir = multiqc(fastqc_dir).report_dir
    report_dir.view { "multiqc report created: ${it.getName()}" }

}
