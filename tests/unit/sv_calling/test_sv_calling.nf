#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { sniffles; cutesv; sv_consensus } from '../../../modules/sv_calling'
// include { multiqc }                       from '../../../modules/qc'

workflow {


    aligned = Channel
        .fromPath(params.bam, checkIfExists:true)
        .map { bam ->
            def sample = bam.simpleName.replaceFirst(/_aligned$/, '')
            tuple(sample, bam, file("${bam}.bai"))      // (sample_id, bam, bai)
        }

    reference_ch = Channel
        .fromPath(params.reference, checkIfExists:true) // broadcast later


    sniffles_out = sniffles(aligned)    
   
    // sniffles_sum = sniffles_out.summary 

    cutesv_out  = cutesv(aligned, reference_ch)  

    // cutesv_sum  = cutesv_out.summary

    sniffles_vcf = sniffles_out.vcf.distinct()   // (sid, path)
    cutesv_vcf   = cutesv_out.vcf.distinct()     // (sid, path)


    consensus_in = sniffles_vcf
                .join(cutesv_vcf, by: 0)     // sid is index 0
                .map { sid, sn_vcf, cu_vcf ->
                    tuple(sid, sn_vcf, cu_vcf)
                }

    // merged_vcf   = sv_consensus(consensus_in).vcf

}
