/*
 * modules/variants/merge/merge_vcfs.nf
 *
 * Two alternative SV‑merging engines.  Both expect a tuple:
 *   (sample_id, vcfs, indexes)
 * where  `vcfs`    is a *list* of bgzipped VCFs
 *        `indexes` is a *list* of the matching *.tbi files
 * Downstream you pick either `.survivor` or `.jasmine`.
 */

process survivorMerge {

    tag "${sample_id}"
    publishDir "${params.outdir}/${sample_id}/variants/sv/merged", mode: 'copy'

    input:
        tuple val(sample_id), val(vcfs), val(indexes)

    output:
        tuple val(sample_id),
              path("${sample_id}.survivor_merged.vcf.gz"),
              path("${sample_id}.survivor_merged.vcf.gz.tbi"),
              emit: survivor

    script:
    """
    printf '%s\n' ${vcfs.join(' ')} | tr ' ' '\n' > vcf_list.txt

    SURVIVOR merge vcf_list.txt \
        ${params.sv_merge_distance     ?: 1000} \
        ${params.sv_merge_caller_count ?: 2}    \
        ${params.sv_merge_same_type    ?: 1}    \
        ${params.sv_merge_same_strand  ?: 1}    \
        ${params.sv_merge_estimate_distance ?: 1} \
        ${params.min_sv_length ?: 30} \
        ${sample_id}.survivor_merged.vcf

    bgzip ${sample_id}.survivor_merged.vcf
    tabix -p vcf ${sample_id}.survivor_merged.vcf.gz
    """
}

process jasmineMerge {

    tag "${sample_id}"
    publishDir "${params.outdir}/${sample_id}/variants/sv/merged", mode: 'copy'

    input:
        tuple val(sample_id), val(vcfs), val(indexes)

    output:
        tuple val(sample_id),
              path("${sample_id}.jasmine_merged.vcf.gz"),
              path("${sample_id}.jasmine_merged.vcf.gz.tbi"),
              emit: jasmine

    script:
    """
    jasmine \\
        file_list="${vcfs.join(',')}" \\
        out_file=${sample_id}.jasmine_merged.vcf \\
        max_dist=${params.sv_merge_distance     ?: 1000} \\
        min_support=${params.sv_merge_caller_count ?: 2}

    bgzip  ${sample_id}.jasmine_merged.vcf
    tabix -p vcf ${sample_id}.jasmine_merged.vcf.gz
    """
}

