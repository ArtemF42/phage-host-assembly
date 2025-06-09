import os

include: workflow.source_path('utils.py')

cwd = os.getcwd()
samples = get_samples(config)

envvars:
    'KRAKEN2DB'

rule classify:
    input:
        expand(os.path.join(cwd, '{sample}', 'taxonomy', '{sample}.krona.html'), sample=samples)

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
        '--gzip-compressed --paired {input.r1} {input.r2}'

rule krona:
    input:
        os.path.join(cwd, '{sample}', 'taxonomy', '{sample}.kraken2.report')
    output:
        os.path.join(cwd, '{sample}', 'taxonomy', '{sample}.krona.html')
    shell:
        'ktImportTaxonomy -t 5 -m 3 -o {output} {input}'
