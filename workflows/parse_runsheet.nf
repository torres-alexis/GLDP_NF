def colorCodes = [
    c_line: "┅" * 70,
    c_back_bright_red: "\u001b[41;1m",
    c_bright_green: "\u001b[32;1m",
    c_blue: "\033[0;34m",
    c_yellow: "\u001b[33;1m",
    c_reset: "\033[0m"
]
// Adapted from Function: https://github.com/nf-core/rnaseq/blob/master/modules/local/process/samplesheet_check.nf
// Function to get list of [ meta, [ fastq_1_path, fastq_2_path ] ]
def get_runsheet_paths(LinkedHashMap row) {
    def meta = [:]
    meta.id = row["Sample Name"]
    meta.organism_sci = row.organism.replaceAll(" ","_").toLowerCase()
    meta.paired_end = row.paired_end.toBoolean()
    meta.has_ercc = row.has_ERCC.toBoolean()

    // Extract factors
    meta.factors = row.findAll { key, value -> 
        key.startsWith("Factor Value[") && key.endsWith("]")
    }.collectEntries { key, value ->
        [(key[13..-2]): value] // Remove "Factor Value[" and "]"
    }

    // Create array of metadata and raw reads
    def raw_reads = []
    raw_reads.add(row.read1_path)
    if (meta.paired_end) {
        raw_reads.add(row.read2_path)
    }
    
    return [meta, raw_reads]
}

def mutate_to_single_end(it) {
  new_meta = it[0]
  new_meta["paired_end"] = false
  return [new_meta, it[1]]
}

workflow PARSE_RUNSHEET {
    take:
        ch_runsheet
        force_single_end
        limit_samples_to
    
    main:
        ch_samples = ch_runsheet 
            | splitCsv(header: true)
            | map { row -> get_runsheet_paths(row) }

        // Print autodetected processing metadata for the first sample
        ch_samples.take(1) | view { meta, reads -> 
            """${colorCodes.c_bright_green}Sample 1 Metadata:
            Sample ID: ${meta.id}
            Has ERCC: ${meta.has_ercc}
            Paired End: ${meta.paired_end}
            Organism: ${meta.organism_sci}
            Read File(s): ${reads.join(', ')}${colorCodes.c_reset}"""
        }
        // Validate consistency across samples
        ch_samples
            .map { meta, reads -> [meta.has_ercc, meta.paired_end, meta.organism_sci] }
            .unique()
            .count()
            .subscribe { count ->
                if (count > 1) {
                    log.error "${colorCodes.c_back_bright_red}ERROR: Inconsistent metadata across samples. Please check the runsheet.${colorCodes.c_reset}"
                    exit 1
                } else {
                    println "${colorCodes.c_bright_green}Metadata consistency check passed.${colorCodes.c_reset}"
                }
            }
        // Check that all read files are unique
        ch_samples
            .flatMap { meta, reads -> reads }
            .collect()
            .map { all_reads ->
                def total_count = all_reads.size()
                def unique_count = all_reads.toSet().size()
                
                if (unique_count != total_count) {
                    throw new RuntimeException("${colorCodes.c_back_bright_red}ERROR: Duplicate read files detected. Please check the runsheet.${colorCodes.c_reset}")
                } else {
                    println "${colorCodes.c_bright_green}All ${unique_count} read files are unique.${colorCodes.c_reset}"
                }
        }

    emit:
        samples = ch_samples
}
