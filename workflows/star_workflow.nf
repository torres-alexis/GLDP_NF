include { STAGE_ANALYSIS } from './stage_analysis.nf'
include { FASTQC as RAW_FASTQC } from '../modules/fastqc.nf'
include { GET_MAX_READ_LENGTH } from '../modules/get_max_read_length.nf'
workflow STAR_WORKFLOW {
    STAGE_ANALYSIS()
    ch_raw_reads = STAGE_ANALYSIS.out.raw_reads

    RAW_FASTQC(ch_raw_reads)

    ch_fastqc_zip = RAW_FASTQC.out.zip
        .map { meta, zip -> zip }
        .collect()

    GET_MAX_READ_LENGTH(ch_fastqc_zip)

    max_read_length = GET_MAX_READ_LENGTH.out.length

    // Add a view to see the maximum read length
    max_read_length.view { "Max read length: $it" }
}
