process indexReference {
    tag "${reference.simpleName}"
    publishDir "${params.outdir}/reference", mode: 'copy'

    input:
        path reference
    output:
        path "${reference.simpleName}.mmi", emit: indexed_reference

    script:
    """
    pbmm2 index ${reference} ${reference.simpleName}.mmi
    """
}

process pbmm2Align {
    tag "${bam.simpleName}"
    publishDir "${params.outdir}/${bam.simpleName}/alignment", mode: 'copy'

    /*
     * When the index channel contains a single file,
     * Nextflow automatically broadcasts it to every BAM.
     */
    input:
        path indexed_reference
        tuple val(sample_id), path(bam)

    output:
        tuple val(sample_id),
              path("${sample_id}_aligned.bam"),
              path("${sample_id}_aligned.bam.bai"),
              emit: aligned

    script:
    """
    pbmm2 align ${indexed_reference} ${bam} \
        ${sample_id}_aligned.bam --preset CCS --sort \
        -j ${params.threads}

    samtools index ${sample_id}_aligned.bam
    """
}

process alignmentStats {
    tag "${sample_id}"
    publishDir "${params.outdir}/${sample_id}/qc/alignment", mode: 'copy'

    input:
        tuple val(sample_id), path(bam), path(bai)

    output:
        tuple val(sample_id), path("${sample_id}_alignment_qc"), emit: stats_dir

    script:
    """
    mkdir ${sample_id}_alignment_qc
    samtools stats    ${bam} > ${sample_id}_alignment_qc/${sample_id}.stats.txt
    samtools flagstat ${bam} > ${sample_id}_alignment_qc/${sample_id}.flagstat.txt
    samtools idxstats ${bam} > ${sample_id}_alignment_qc/${sample_id}.idxstats.txt
    """
}

process mosdepthCoverage {
    tag "${sample_id}"
    publishDir "${params.outdir}/${sample_id}/qc/mosdepth", mode: 'copy'

    input:
        tuple val(sample_id), path(aligned_bam), path(bai)

    output:
        tuple val(sample_id), path("${sample_id}_mosdepth"), emit: mosdepth_dir

    script:
    """
    mkdir ${sample_id}_mosdepth
    mosdepth --fast-mode --by 500 --no-per-base \
             --threads ${params.threads} \
             ${sample_id}_mosdepth/${sample_id} ${aligned_bam}
    """
}

process multiqc {
    tag "${sample_id}"
    publishDir "${qc_dir}", mode: 'copy'

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
