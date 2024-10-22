process FASTQC {
  // memory and versioning adapted from https://github.com/nf-core/modules/blob/master/modules/nf-core/fastqc/main.nf
  // FastQC performed on reads
  tag "${ meta.id }"
  label 'low_cpu_memory'

  input:
    tuple val(meta), path(reads)

  output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip") , emit: zip
    path "versions.yml"            , emit: versions

  script:
    // Calculate memory per thread (100MB minimum, 10000MB maximum)
    def memory_in_mb = MemoryUnit.of("${task.memory}").toUnit('MB') / task.cpus
    def fastqc_memory = memory_in_mb > 10000 ? 10000 : (memory_in_mb < 100 ? 100 : memory_in_mb)

    """
    fastqc \\
        -o . \\
        -t $task.cpus \\
        --memory $fastqc_memory \\
        $reads

    echo '"${task.process}":' > versions.yml
    echo "    fastqc: \$(fastqc --version | sed -e 's/FastQC v//g')" >> versions.yml
    """
}