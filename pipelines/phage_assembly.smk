import os

include: workflow.source_path('utils.py')

cwd = os.getcwd()
samples = get_samples(config)

envvars:
    'CHECKVDB'

rule assemble:
    input:
        expand(os.path.join(cwd, '{sample}', '{sample}.fasta'), sample=samples)

rule seqtk:
    input:
        r1 = os.path.join(cwd, '{sample}', 'reads', '{sample}_R1.fq.gz'),
        r2 = os.path.join(cwd, '{sample}', 'reads', '{sample}_R2.fq.gz'),
    output:
        r1 = os.path.join(cwd, '{sample}', 'reads', '{sample}_sampled_R1.fq.gz'),
        r2 = os.path.join(cwd, '{sample}', 'reads', '{sample}_sampled_R2.fq.gz'),
    params:
        sample_size = config.get('sample-size', 10_000)
    shell:
        'seqtk sample -s42 {input.r1} {params.sample_size} | gzip > {output.r1} && '
        'seqtk sample -s42 {input.r2} {params.sample_size} | gzip > {output.r2}'

rule spades:
    input:
        r1 = os.path.join(cwd, '{sample}', 'reads', '{sample}_sampled_R1.fq.gz'),
        r2 = os.path.join(cwd, '{sample}', 'reads', '{sample}_sampled_R2.fq.gz'),
    output:
        os.path.join(cwd, '{sample}', 'assembly', 'contigs.fasta')
    params:
        outdir = os.path.join(cwd, '{sample}', 'assembly')
    threads:
        config.get('threads', 1)
    shell:
        'spades.py --only-assembler -1 {input.r1} -2 {input.r2} --threads {threads} -o {params.outdir}'

rule checkv:
    input:
        os.path.join(cwd, '{sample}', 'assembly', 'contigs.fasta')
    output:
        os.path.join(cwd, '{sample}', 'checkv', 'quality_summary.tsv')
    params:
        outdir =  os.path.join(cwd, '{sample}', 'checkv')
    threads:
        config.get('threads', 1)
    shell:
        'checkv end_to_end -t {threads} {input} {params.outdir}'

rule extract:
    input:
        quality_summary = os.path.join(cwd, '{sample}', 'checkv', 'quality_summary.tsv'),
        contigs = os.path.join(cwd, '{sample}', 'assembly', 'contigs.fasta'),
    output:
        os.path.join(cwd, '{sample}', '{sample}.fasta')
    script:
        'scripts/extract_complete_genome.py'
