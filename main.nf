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

// Import modules
include { FETCH_ISA } from './modules/fetch_isa.nf'
include { ISA_TO_RUNSHEET } from './modules/isa_to_runsheet.nf'
include { RAW_READS_HANDLING } from './modules/raw_reads_handling.nf'
include { get_runsheet_paths } from './modules/parse_runsheet.nf'

// Main workflow
workflow {

    // Set up channels
    def ch_dp_tools_plugin = params.dp_tools_plugin ? 
        Channel.value(file(params.dp_tools_plugin)) : 
        Channel.value(file(params.mode == 'microbes' ? 
            "$projectDir/bin/dp_tools__NF_RCP_Bowtie2" : 
            "$projectDir/bin/dp_tools__NF_RCP"))

    def ch_glds = params.glds ? Channel.value(params.glds) : null
    def ch_osd = params.osd ? Channel.value(params.osd) : null
    def ch_runsheet_path = params.runsheet_path ? Channel.fromPath(params.runsheet_path) : null

    // Runsheet-based run
    if (ch_runsheet_path) {
        ch_runsheet = ch_runsheet_path
    } else { // GLDS/OSD run
        // Fetch ISA from OSDR
        FETCH_ISA( ch_osd, ch_glds )
        ch_isa = FETCH_ISA.out.isa_archive
        
        // Convert ISA to runsheet
        ISA_TO_RUNSHEET( ch_glds, ch_isa, ch_dp_tools_plugin )
        ch_runsheet = ISA_TO_RUNSHEET.out.runsheet
    }
    // Sample metadata structure
    // meta = [
    //     id: "Sample1",
    //     organism_sci: "mus_musculus",
    //     paired_end: true,
    //     has_ercc: false,
    //     factors: [
    //         "Treatment": "Control",
    //         "Time": "24h",
    //         "Replicate": "1"
    //     ]
    // ]
    ch_samples = ch_runsheet
        | splitCsv(header: true)
        | map { row -> get_runsheet_paths(row) }
        | map { it -> params.force_single_end ? mutate_to_single_end(it) : it }
        | take(params.limit_samples_to ?: -1)

        // Uncomment to view the samples
        // | view { meta, reads -> 
        //     """
        //     Sample ID: ${meta.id}
        //     Organism: ${meta.organism_sci}
        //     Paired End: ${meta.paired_end}
        //     Has ERCC: ${meta.has_ercc}
        //     Factors: ${meta.factors.collect { factor, value -> "${factor}: ${value}" }.join(', ')}
        //     Read 1: ${reads[0]}
        //     ${meta.paired_end ? "Read 2: ${reads[1]}" : ""}
        //     ------------------------
        //     """
        // }
        | set { ch_samples }

    // Handle raw reads
    // RAW_READS_HANDLING(
    //     runsheet: ch_runsheet,
    //     truncateTo: params.truncateTo,
    //     force_single_end: params.force_single_end,
    //     limitSamplesTo: params.limitSamplesTo,
    //     stageLocal: params.stageLocal
    // )

    // Proceed with the rest of the workflow based on params.mode
    // if (params.mode && params.mode == 'microbes') {
    //     BOWTIE2_WORKFLOW(
    //         runsheet: ch_runsheet,
    //         raw_reads: RAW_READS_HANDLING.out.raw_reads
    //     )
    // } else {
    //     STAR_WORKFLOW(
    //         runsheet: ch_runsheet,
    //         raw_reads: RAW_READS_HANDLING.out.raw_reads
    //     )
    // }
}
