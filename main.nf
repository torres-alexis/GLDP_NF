// main.nf

nextflow.enable.dsl=2

def colorCodes = [
    c_line: "┅" * 70,
    c_back_bright_red: "\u001b[41;1m",
    c_bright_green: "\u001b[32;1m",
    c_blue: "\033[0;34m",
    c_yellow: "\u001b[33;1m",
    c_reset: "\033[0m"
]


// Include the showHelp function from help.nf
include { showHelp } from './modules/help.nf'
// Only display the help message if --help parameter is specified
if (params.help) {
    showHelp(workflow)
}

// Print the pipeline version
println """
${colorCodes.c_bright_green}${colorCodes.c_line}
GeneLab RNA-Seq Consensus Pipeline NF-RCP-${workflow.manifest.version}
${colorCodes.c_line}${colorCodes.c_reset}
""".stripIndent()

// Debug warning
println("${colorCodes.c_yellow}")
if (params.limit_samples_to || params.truncate_to || params.force_single_end || params.genome_subsample) {
    println("WARNING: Debugging options enabled!")
    println("Sample limit: ${params.limit_samples_to ?: 'Not set'}")
    println("Read truncation: ${params.truncate_to ? "First ${params.truncate_to} records" : 'Not set'}")
    println("Reference genome subsampling: ${params.genome_subsample ? "Chromosome '${params.genome_subsample}'" : 'Not set'}")
    println("Force single-end analysis: ${params.force_single_end ? 'Yes' : 'No'}")
} else {
    println("No debugging options enabled")
}
println("${colorCodes.c_reset}")

// Check required parameters
if ((params.glds && params.osd) || params.runsheet_path) {
    // Proceed
} else {
    log.error """
        Missing Required Parameters: You must provide either both --osd and --glds, or --runsheet_path.
        Examples:
          --osd 194 --glds 194
          --runsheet_path /path/to/runsheet.csv
    """
    exit 0
}

// Import modules and subworkflows
// include { FETCH_ISA } from './modules/fetch_isa.nf'
// include { ISA_TO_RUNSHEET } from './modules/isa_to_runsheet.nf'
// include { PARSE_RUNSHEET } from './workflows/parse_runsheet.nf'
// include { STAGE_RAW_READS } from './workflows/stage_raw_reads.nf'
// include { STAR_WORKFLOW } from './workflows/star_workflow.nf'
include { STAGE_ANALYSIS } from './workflows/stage_analysis.nf'

// Set up channels
ch_dp_tools_plugin = params.dp_tools_plugin ? 
    Channel.value(file(params.dp_tools_plugin)) : 
    Channel.value(file(params.mode == 'microbes' ? 
        "$projectDir/bin/dp_tools__NF_RCP_Bowtie2" : 
        "$projectDir/bin/dp_tools__NF_RCP"))
ch_glds = params.glds ? Channel.value(params.glds) : null
ch_osd = params.osd ? Channel.value(params.osd) : null
ch_runsheet = params.runsheet_path ? Channel.fromPath(params.runsheet_path) : null
ch_isa_archive = params.isa_archive_path ? Channel.fromPath(params.isa_archive_path) : null
ch_force_single_end = Channel.value(params.force_single_end)
ch_limit_samples_to = Channel.value(params.limit_samples_to)

// Main workflow
// workflow {
//     if (params.mode == 'microbes') {
//         //BOWTIE2_WORKFLOW()
//     } else {
//         STAR_WORKFLOW()
//     }
// }
workflow {
    STAGE_ANALYSIS(
        ch_runsheet,
        ch_isa_archive,
        ch_osd,
        ch_glds,
        ch_dp_tools_plugin,
        ch_force_single_end,
        ch_limit_samples_to
    )
}