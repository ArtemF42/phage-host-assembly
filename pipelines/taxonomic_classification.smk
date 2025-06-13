import os

include: workflow.source_path('utils.py')

cwd = os.getcwd()
samples = get_samples(config)

envvars:
    'KRAKEN2DB'

rule classify:
    input:
        expand(os.path.join(cwd, '{sample}', 'taxonomy', '{sample}.krona.html'), sample=samples)

rule filter:
    input:
        expand(os.path.join(cwd, '{sample}', 'reads', '{sample}_filtered_R1.fq.gz'), sample=samples)

rule kraken2:
    input:
        r1 = os.path.join(cwd, '{sample}', 'reads', '{sample}_R1.fq.gz'),
        r2 = os.path.join(cwd, '{sample}', 'reads', '{sample}_R2.fq.gz'),
    params:
        db = os.environ['KRAKEN2DB']
    threads:
        config.get('threads', 1)
    output:
        output = os.path.join(cwd, '{sample}', 'taxonomy', '{sample}.kraken2.output'),
        report = os.path.join(cwd, '{sample}', 'taxonomy', '{sample}.kraken2.report'),
    shell:
        'kraken2 --db {params.db} --threads {threads} --output {output.output} --report {output.report} '
        '--memory-mapping --gzip-compressed --paired {input.r1} {input.r2}'

rule krona:
    input:
        os.path.join(cwd, '{sample}', 'taxonomy', '{sample}.kraken2.report')
    output:
        os.path.join(cwd, '{sample}', 'taxonomy', '{sample}.krona.html')
    shell:
        'ktImportTaxonomy -t 5 -m 3 -o {output} {input}'

rule extract_kraken_reads:
    # See https://github.com/jenniferlu717/KrakenTools?tab=readme-ov-file#extract_kraken_readspy for details
    input:
        r1 = os.path.join(cwd, '{sample}', 'reads', '{sample}_R1.fq.gz'),
        r2 = os.path.join(cwd, '{sample}', 'reads', '{sample}_R2.fq.gz'),
        kraken2_output = os.path.join(cwd, '{sample}', 'taxonomy', '{sample}.kraken2.output'),
        kraken2_report = os.path.join(cwd, '{sample}', 'taxonomy', '{sample}.kraken2.report'),
    params:
        executable = workflow.source_path('scripts/extract_kraken_reads.py'),
        taxid = config['taxid'],
    output:
        r1 = os.path.join(cwd, '{sample}', 'reads', '{sample}_filtered_R1.fq.gz'),
        r2 = os.path.join(cwd, '{sample}', 'reads', '{sample}_filtered_R2.fq.gz'),
    shell:
        'python {params.executable} -s1 {input.r1} -s2 {input.r2} -o {output.r1} -o2 {output.r2} '
        '-k {input.kraken2_output} -r {input.kraken2_report} --taxid {params.taxid} --exclude --include-children'
