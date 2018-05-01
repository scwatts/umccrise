## Cancer gene coverage
# Looking at coverage for a limited set of (cancer) genes to assess overall reliability. 
# Minimum coverage for normal is 10, 30 for cancer.
# TODO: replace with mosdepth
rule goleft_depth:
    input:
        bam = lambda wc: getattr(batch_by_name[wc.batch], wc.phenotype).bam,
        az300 = az300,
        ref_fa = ref_fa
    params:
        prefix = lambda wc, output: output[0].replace('.depth.bed', ''),
        cutoff = lambda wc: cov_by_phenotype[wc.phenotype]
    output:
        '{batch}/coverage/{batch}-{phenotype}.depth.bed'
    threads: max(1, threads_max // len(batch_by_name))
    shell:
        'goleft depth {input.bam} --reference {ref_fa} --processes {threads} --bed {az300} --stats --mincov {params.cutoff} --prefix {params.prefix}'


# Also bringing in global coverage plots for review (tumor only, quick check for CNVs):
rule goleft_plots:
    input:
        bam = lambda wc: batch_by_name[wc.batch].tumor.bam
    params:
        directory = '{batch}/coverage/{batch}-indexcov'
    output:
        '{batch}/coverage/{batch}-indexcov/index.html'
    shell:
        'goleft indexcov --directory {params.directory} {input.bam} --sex X'


rule coverage:
    input:
        expand(rules.goleft_depth.output[0], phenotype=['tumor', 'normal'], batch=batch_by_name.keys()),
        expand(rules.goleft_plots.output[0], batch=batch_by_name.keys())
    output:
        temp(touch('coverage.done'))