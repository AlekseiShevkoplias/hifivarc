nextflow.enable.dsl=2

include { seqkitStats; nanoplot; fastqc; multiqc } from '../../../modules/qc'

workflow {
    samples = Channel
        .fromPath(params.test_fastq, checkIfExists: true)
        .map { f -> tuple(f.simpleName, f) }          // (sample_id, fastq)

    seqkit_out   = seqkitStats(samples).stats_dir      // (sample_id, path)
    nanoplot_out = nanoplot(samples).nanoplot_dir
    fastqc_out   = fastqc(samples).fastqc_dir

    // collect all QC‑channels in a list 
    qc_channels = [ seqkit_out, nanoplot_out, fastqc_out ]

    // fold the list with successive join() calls on sample_id (index 0)
    qc_ready = qc_channels
        .drop(1)                        // everything but the first channel
        .inject(qc_channels.first()) { acc, ch -> acc.join(ch, by: 0) }
        .map { t ->
            def sid = t[0]              // sample_id
            tuple( sid, file("${params.outdir}/${sid}/qc") )
        }                               // -> (sample_id, qc_dir)

    multiqc(qc_ready)
}
