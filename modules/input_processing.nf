
process bamToFastq {

    tag "${sample_id}"
    publishDir "${params.outdir}/${sample_id}/fastq",
               mode: 'copy',
               enabled: params.save_intermediates

    input:
        tuple val(sample_id), path(bam)

    output:
        tuple val(sample_id), path("${sample_id}.fastq.gz"), emit: fastq

    script:
    """
    samtools fastq ${bam} | gzip > ${sample_id}.fastq.gz
    """
}

process filterReadQuality {

    tag "${sample_id}"
    publishDir "${params.outdir}/${sample_id}/fastq_filtered",
               mode: 'copy',
               enabled: params.save_intermediates

    input:
        tuple val(sample_id), path(fastq)

    output:
        tuple val(sample_id),
              path("${sample_id}_filtered.fastq.gz"),
              emit: filtered_fastq

    when:
        params.filter_reads

    script:
    """
    seqkit seq -m ${params.min_read_length}  ${fastq} | \
    seqkit seq -Q ${params.min_read_quality} | \
    gzip > ${sample_id}_filtered.fastq.gz
    """
}
