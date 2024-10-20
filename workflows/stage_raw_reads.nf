nextflow.enable.dsl=2

workflow STAGE_RAW_READS {
    take:
    ch_samples       // Channel of sample information
    stage_local      // Boolean (placeholder for now)
    truncate_to      // Integer or false (placeholder for now)

    main:
    PRINT_SAMPLE_INFO(ch_samples)
}

// Process to print sample information
process PRINT_SAMPLE_INFO {
    tag "${meta.id}"

    input:
    tuple val(meta), val(reads)

    // script:
    // """
    // """
    exec:
    println "Sample ID: ${meta.id}"
    println "Organism: ${meta.organism_sci}"
    println "Paired-end: ${meta.paired_end}"
    println "Has ERCC: ${meta.has_ercc}"
    println "Factors: ${meta.factors}"
    println "Read files: ${reads}"
    println "--------------------"
}
