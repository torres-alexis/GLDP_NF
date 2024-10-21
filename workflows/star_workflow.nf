include { STAGE_ANALYSIS } from './stage_analysis.nf'
include { FASTQC as RAW_FASTQC } from '../modules/fastqc.nf'
workflow STAR_WORKFLOW {
    STAGE_ANALYSIS()
    ch_raw_reads = STAGE_ANALYSIS.out.raw_reads

    RAW_FASTQC(ch_raw_reads)
}