nextflow.enable.dsl=2

workflow STAGE_RAW_READS {
    take:
        ch_samples
        stageLocal
        truncateTo

    main:
        STAGE_READS(ch_samples)

    emit:
        staged_reads = STAGE_READS.out.raw_reads
}

process STAGE_READS {
    // Stages the raw reads into appropriate publish directory
    tag "${ meta.id }"

    input:
        tuple val(meta), path("?.gz")

    output:
        tuple val(meta), path("${meta.id}*.gz"), emit: raw_reads

    script:
        if ( meta.paired_end ) {
        """
        cp -P 1.gz ${meta.id}_R1_raw.fastq.gz
        cp -P 2.gz ${meta.id}_R2_raw.fastq.gz
        """
        } else {
        """
        cp -P 1.gz  ${meta.id}_raw.fastq.gz
        """
        }
    }
