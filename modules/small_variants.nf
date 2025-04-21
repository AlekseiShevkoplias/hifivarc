process faidxReference {

    tag "${reference.simpleName}"
    publishDir "${params.outdir}/reference", mode: 'copy'

    input:
        path reference

    output:
        path "${reference}.fai", emit: ref_index

    script:
    """
    samtools faidx ${reference}
    """
}

process pepperDeepVariant {

    tag "${sample_id}"
    publishDir "${params.outdir}/${sample_id}/variants/small", mode: 'copy'

    input:
        tuple val(sample_id), path(bam), path(bai)
        path reference
        path ref_index                                    // broadcast

    output:
        tuple val(sample_id),
              path("${sample_id}.pepper.deepvariant.vcf.gz"),
              path("${sample_id}.pepper.deepvariant.vcf.gz.tbi"),
              emit: vcf

    /*
     * PEPPER container needs absolute host paths; we create them once
     * with realpath so the command stays readable.
     */
    script:
    def model  = params.platform?.toLowerCase() == 'pacbio' ? '--pacbio' : '--ont'

    """
    REF_DIR=\$(dirname \$(realpath ${reference}))
    BAM_DIR=\$(dirname \$(realpath ${bam}))
    OUT_DIR=\$(pwd)

    docker run --rm \\
       -v \${REF_DIR}:/ref \\
       -v \${BAM_DIR}:/input \\
       -v \${OUT_DIR}:/output \\
       kishwars/pepper_deepvariant:r0.8 \\
       run_pepper_margin_deepvariant call_variant \\
       -b /input/${bam.getName()} \\
       -f /ref/${reference.getName()} \\
       -o /output \\
       -p ${sample_id}.pepper \\
       -t ${params.threads} \\
       ${model} \\
    #   --only_cpu
    """
}

process longshot {

    tag "${sample_id}"
    publishDir "${params.outdir}/${sample_id}/variants/small", mode: 'copy'

    input:
        tuple val(sample_id), path(bam), path(bai)
        path reference
        path ref_idx

    output:
        tuple val(sample_id),
              path("${sample_id}.longshot.vcf.gz"),
              path("${sample_id}.longshot.vcf.gz.tbi"),
              emit: vcf

    script:
    """
    longshot --bam ${bam} --ref ${reference} --out ${sample_id}.longshot.vcf

    bgzip  ${sample_id}.longshot.vcf
    tabix -p vcf ${sample_id}.longshot.vcf.gz
    """
}
