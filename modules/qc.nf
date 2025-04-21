process seqkitStats {
    tag "${sample_id}"
    publishDir "${params.outdir}/${sample_id}/qc", mode: 'copy'

    input:
    tuple val(sample_id), path(fastq)

    output:
    tuple val(sample_id), path("seqkit_${sample_id}"), emit: stats_dir

    script:
    """
    mkdir seqkit_${sample_id}
    seqkit stats -a ${fastq} > seqkit_${sample_id}/${sample_id}_stats.txt
    """
}

process nanoplot {
    tag "${sample_id}"
    publishDir "${params.outdir}/${sample_id}/qc", mode: 'copy'

    input:
    tuple val(sample_id), path(fastq)

    output:
    tuple val(sample_id), path("nanoplot_${sample_id}"), emit: nanoplot_dir

    script:
    """
    NanoPlot -t ${params.threads} --fastq ${fastq} \
        --loglength -o nanoplot_${sample_id} \
        --N50 --plots ${params.nanoplot_plots} --title "${sample_id}" \
        --format ${params.nanoplot_format}
    """
}


process fastqc {
    tag "${sample_id}"
    publishDir "${params.outdir}/${sample_id}/qc", mode: 'copy'

    input:
    tuple val(sample_id), path(fastq)

    output:
    tuple val(sample_id), path("fastqc_${sample_id}"), emit: fastqc_dir

    when:
    params.fastqc_report

    script:
    """
    mkdir fastqc_${sample_id}
    fastqc -t ${params.threads} -o fastqc_${sample_id} ${fastq}
    """
}

process multiqc {

    tag "${sample_id}"
    publishDir "${params.outdir}/${sample_id}/qc", mode: 'copy'

    input:
    tuple val(sample_id), path(qc_dir)

    output:
    path "multiqc_report", emit: report_dir

    when:
    params.multiqc_report

    script:
    """
    multiqc -o multiqc_report ${qc_dir}
    """
}
