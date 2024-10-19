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