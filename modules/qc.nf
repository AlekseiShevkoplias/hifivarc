process seqkitStats {
    tag "${fastq.simpleName}"
    publishDir "${params.outdir}/qc/seqkit", mode: 'copy'

    input:
    path fastq

    output:
    path "seqkit_${fastq.simpleName}", emit: stats_dir

    script:
    """
    mkdir seqkit_${fastq.simpleName}
    seqkit stats -a ${fastq} > seqkit_${fastq.simpleName}/${fastq.simpleName}_stats.txt
    """
}

process nanoplot {
    tag "${fastq.simpleName}"
    publishDir "${params.outdir}/qc/nanoplot", mode: 'copy'

    input:
    path fastq

    output:
    path "nanoplot_${fastq.simpleName}", emit: nanoplot_dir

    script:
    """
    NanoPlot -t ${params.threads} --fastq ${fastq} \
        --loglength -o nanoplot_${fastq.simpleName} \
        --N50 --plots ${params.nanoplot_plots} --title "${fastq.simpleName}" \
        --format ${params.nanoplot_format}
    """
}

process fastqc {
    tag "${fastq.simpleName}"
    publishDir "${params.outdir}/qc/fastqc", mode: 'copy'

    input:
    path fastq

    output:
    path "fastqc_${fastq.simpleName}", emit: fastqc_dir

    when:
    params.fastqc_report

    script:
    """
    mkdir fastqc_${fastq.simpleName}
    fastqc -t ${params.threads} -o fastqc_${fastq.simpleName} ${fastq}
    """
}

process multiqc {
    tag "multiqc_report"
    publishDir "${params.outdir}/qc/fastqc", mode: 'copy'

    input:
    path fastqc_dir

    output:
    path "multiqc_report", emit: report_dir

    when:
    params.fastqc_report && params.multiqc_report

    script:
    """
    mkdir multiqc_report
    multiqc -o multiqc_report ${fastqc_dir}
    """
}
