include { STAGE_ANALYSIS } from './stage_analysis.nf'
include { FASTQC as RAW_FASTQC } from '../modules/fastqc.nf'
include { GET_MAX_READ_LENGTH } from '../modules/get_max_read_length.nf'
include { TRIMGALORE } from '../modules/trimgalore.nf'
include { MULTIQC as RAW_MULTIQC } from '../modules/multiqc.nf'  addParams(MQCLabel:"raw")
workflow STAR_WORKFLOW {
    STAGE_ANALYSIS()
    ch_raw_reads = STAGE_ANALYSIS.out.raw_reads
    ch_samples_txt = STAGE_ANALYSIS.out.samples_txt

    RAW_FASTQC(ch_raw_reads)

    RAW_FASTQC.out.zip
        .map { meta, zip -> zip }  // Remove the meta information
        .collect()                 // Collect all zip files into a single list
        .set { ch_raw_fastqc_zip }     // Create a channel with all zip files

    
    ch_multiqc_config = params.multiqcConfig ? Channel.fromPath( params.multiqcConfig ) : Channel.fromPath("NO_FILE")
    RAW_MULTIQC( ch_samples_txt, ch_raw_fastqc_zip, ch_multiqc_config  )

    // Get the maximum read length
    GET_MAX_READ_LENGTH(ch_raw_fastqc_zip)
    max_read_length = GET_MAX_READ_LENGTH.out.length

    // View to see the maximum read length
    // max_read_length.view { "Max read length: $it" }

    STAGE_ANALYSIS.out.raw_reads |  TRIMGALORE
}