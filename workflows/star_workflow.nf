include { STAGE_ANALYSIS } from './stage_analysis.nf'

workflow STAR_WORKFLOW {
    STAGE_ANALYSIS()
}