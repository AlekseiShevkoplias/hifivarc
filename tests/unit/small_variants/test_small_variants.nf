#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { faidxReference; pepperDeepVariant; longshot } from '../../../modules/small_variants'
workflow {


    aligned = Channel
        .fromPath(params.bam, checkIfExists:true)
        .map { bam ->
            def sid = bam.baseName.replaceFirst(/_aligned$/, '')
            tuple( sid, bam, file("${bam}.bai") )
        }

    ref_ch   = Channel.value( file(params.reference) )
    ref_idx  = faidxReference(ref_ch).ref_index


    //takes too long for testing!
    // pepper_vcf = pepperDeepVariant(aligned, ref_ch, ref_idx).vcf
    // pepper_vcf.view { "PEPPER done ${it[1].name}" }

    long_vcf   = longshot(aligned, ref_ch, ref_idx).vcf
    long_vcf.view   { "Longshot done ${it[1].name}" }
}
