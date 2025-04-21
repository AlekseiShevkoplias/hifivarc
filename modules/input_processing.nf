process bamToFastq {
    tag "${bam.simpleName}"
    publishDir "${params.outdir}/fastq", mode: 'copy', enabled: params.save_intermediates

    input:
    path bam
    
    output:
    path "${bam.simpleName}.fastq.gz", emit: fastq
    
    script:
    """
    samtools fastq ${bam} | gzip > ${bam.simpleName}.fastq.gz
    """
}

process filterReadQuality {

    // Optional step to filter reads by quality
    // Required params:
    // save_intermediates (default true)
    // min_read_length (default 1000)
    // min_read_quality (default 7)

    tag "${fastq.simpleName}"
    publishDir "${params.outdir}/fastq_filtered", mode: 'copy', enabled: params.save_intermediates
    
    input:
    path fastq
    
    output:
    path "${fastq.simpleName}_filtered.fastq.gz", emit: filtered_fastq
    
    when:
    params.filter_reads
    
    script:
    """
    seqkit seq -m ${params.min_read_length} ${fastq} | \
    seqkit seq -Q ${params.min_read_quality} | \
    gzip > ${fastq.simpleName}_filtered.fastq.gz
    """
}
