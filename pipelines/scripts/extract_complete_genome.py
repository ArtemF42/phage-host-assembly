import logging
import pandas as pd
from Bio import SeqIO
from snakemake.script import snakemake

quality_summary = pd.read_csv(snakemake.input.quality_summary, sep='\t')
complete_genome = quality_summary[quality_summary.checkv_quality == 'Complete']

if complete_genome.empty:
    msg = f'No complete genomes were detected for {snakemake.input.contigs}. Manual review is recommended.'
    logging.warning(msg)

    with open(snakemake.output[0], mode='w') as file:
        # Create empty file to avoid pipeline failure
        pass
else:
    if len(complete_genome) > 1:
        msg = f'Multiple complete genomes were detected for {snakemake.input.contigs}. The first one will be used.'
        logging.warning(msg)

    contig_id = complete_genome.contig_id.item()
    contigs = SeqIO.index(snakemake.input.contigs, 'fasta')

    with open(snakemake.output[0], mode='w') as file:
        SeqIO.write(contigs[contig_id], file, 'fasta')
