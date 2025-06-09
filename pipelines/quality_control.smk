import os

include: workflow.source_path('utils.py')

cwd = os.getcwd()
samples = get_samples(config)

rule qc:
    input:
        os.path.join(cwd, 'multiqc_report.html')

rule fastp:
    input:
        r1 = os.path.join(cwd, 'raw-reads', '{sample}_R1.fq.gz'),
        r2 = os.path.join(cwd, 'raw-reads', '{sample}_R2.fq.gz'),
    output:
        r1 = os.path.join(cwd, '{sample}', 'reads', '{sample}_R1.fq.gz'),
        r2 = os.path.join(cwd, '{sample}', 'reads', '{sample}_R2.fq.gz'),
        json = os.path.join(cwd, '{sample}', 'qc', '{sample}.fastp.json'),
        html = os.path.join(cwd, '{sample}', 'qc', '{sample}.fastp.html'),
    threads: max(16, config.get('threads', 1))
    shell:
        'fastp -i {input.r1} -I {input.r2} -o {output.r1} -O {output.r2} -j {output.json} -h {output.html} -w {threads}'

rule multiqc:
    input:
        expand(os.path.join(cwd, '{sample}', 'qc', '{sample}.fastp.json'), sample=samples)
    output:
        os.path.join(cwd, 'multiqc_report.html')
    shell:
        'multiqc -o {cwd} {cwd}'
