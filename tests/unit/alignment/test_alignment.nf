nextflow.enable.dsl = 2

include { indexReference; pbmm2Align; alignmentStats; mosdepthCoverage } from '../../../modules/mapping'
include { fastqc; multiqc } from '../../../modules/qc'
include { bamToFastq } from '../../../modules/input_processing'

workflow {
    bams = Channel
        .fromPath(params.bam, checkIfExists: true)
        .map { f -> tuple(f.simpleName, f) }          // (sample_id, bam)

    fastq  = bamToFastq(bams).fastq   
    fastqc_out   = fastqc(fastq).fastqc_dir
    

    ref_index = indexReference(Channel.fromPath(params.reference, checkIfExists:true)).indexed_reference

    aligned = pbmm2Align(ref_index, bams).aligned     // (sample_id, bam, bai)
    stats_out    = alignmentStats(aligned).stats_dir
    mosdepth_out = mosdepthCoverage(aligned).mosdepth_dir
    qc_channels = [fastqc_out, stats_out, mosdepth_out]

    qc_ready = qc_channels
        .drop(1)
        .inject(qc_channels.first()) { acc, ch -> acc.join(ch, by: 0) }
        .map { t ->
            def sid = t[0]
            tuple(sid, file("${params.outdir}/${sid}/qc"))
        }

    multiqc(qc_ready)
}
