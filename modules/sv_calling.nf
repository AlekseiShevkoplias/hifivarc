process sniffles {

    tag "${sample_id}"
    publishDir "${params.outdir}/${sample_id}/sv_calling/sniffles", mode: 'copy'

    input:
        tuple val(sample_id), path(bam), path(bai)

    output:
        tuple val(sample_id), path("${sample_id}_sniffles.vcf"),         emit: vcf
        tuple val(sample_id), path("${sample_id}_sniffles_precise.vcf"), emit: precise_vcf
        tuple val(sample_id), path("${sample_id}_sniffles_summary*"),    emit: summary

    script:
    """
    # Sniffles ≥ 2 syntax
    sniffles --input    ${bam} \
             --vcf      ${sample_id}_sniffles.vcf \
             --threads  ${params.threads}

    # keep only precise calls
    grep -v "IMPRECISE" ${sample_id}_sniffles.vcf \
        > ${sample_id}_sniffles_precise.vcf

    # summary statistics
    SURVIVOR stats ${sample_id}_sniffles.vcf -1 -1 -1 \
        ${sample_id}_sniffles_summary_stats \
        > ${sample_id}_sniffles_summary.txt
    """
}


process cutesv {

    tag "${sample_id}"
    publishDir "${params.outdir}/${sample_id}/sv_calling/cutesv", mode: 'copy'

    input:
        tuple val(sample_id), path(bam), path(bai)
        path reference                                    // broadcast to all samples

    output:
        tuple val(sample_id), path("${sample_id}_cutesv.vcf"),       emit: vcf
        tuple val(sample_id), path("${sample_id}_cutesv_summary*"),  emit: summary

    // IMPORTANT: make params configurable!! 
    script:
    """
    mkdir -p cutesv_tmp

    cuteSV -t ${params.threads} \
           --max_cluster_bias_INS 1000  --diff_ratio_merging_INS 0.9 \
           --max_cluster_bias_DEL 1000  --diff_ratio_merging_DEL 0.5 \
           ${bam} ${reference} ${sample_id}_cutesv.vcf ./cutesv_tmp/

    SURVIVOR stats ${sample_id}_cutesv.vcf -1 -1 -1 \
        ${sample_id}_cutesv_summary_stats \
        > ${sample_id}_cutesv_summary.txt
    """
}

process sv_consensus {

    tag "${sample_id}"
    publishDir "${params.outdir}/${sample_id}/sv_calling/consensus", mode: 'copy'

    input:
        tuple val(sample_id), path(sniffles_vcf), path(cutesv_vcf)

    output:
        tuple val(sample_id), path("survivor_merged.vcf"),          emit: vcf
        tuple val(sample_id), path("survivor_merged_summary*"),     emit: summary

    script:
    """
    printf '%s\n%s\n' "${sniffles_vcf}" "${cutesv_vcf}" > sample_files

    # min distance=1000bp, require calls in ≥2 callers, keep all strands etc.
    SURVIVOR merge sample_files 1000 2 1 1 1 30 survivor_merged.vcf

    SURVIVOR stats survivor_merged.vcf -1 -1 -1 \
        survivor_merged_stats \
        > survivor_merged_summary.txt
    """
}
