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
        | map { it -> force_single_end ? mutate_to_single_end(it) : it }
        | take(limit_samples_to ?: -1)

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

    emit:
    samples = ch_samples
}