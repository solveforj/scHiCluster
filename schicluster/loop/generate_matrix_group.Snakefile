

import pathlib
output_dir = pathlib.Path(output_dir).absolute()
groups = set([p.name.split('_chunk')[0] for p in output_dir.glob('*_chunk*')])


# check if all the chunks completed
from schicluster.loop.snakemake import check_chunk_dir_finish
check_chunk_dir_finish(output_dir)

matrix_types = ['Q', 'E', 'E2', 'T', 'T2']

rule summary:
    input:
        expand('{group}/{group}.loop_info.hdf', group=groups),
        expand('{group}/{group}.loop.multires', group=groups),
        expand('{group}/{group}.loop_summit.multires', group=groups),
        expand('{group}/{group}.Q.mcool', group=groups)


rule zoomify_loop:
    input:
        '{group}/{group}.loop.bedpe'
    output:
        '{group}/{group}.loop.multires'
    threads:
        1
    shell:
        'clodius aggregate bedpe '
        '--assembly {genome} '
        '--chr1-col 1 --from1-col 2 --to1-col 3 '
        '--chr2-col 4 --from2-col 5 --to2-col 6 '
        '--output-file {output} {input}'


rule zoomify_loop_summit:
    input:
        '{group}/{group}.loop_summit.bedpe'
    output:
        '{group}/{group}.loop_summit.multires'
    threads:
        1
    shell:
        'clodius aggregate bedpe '
        '--assembly {genome} '
        '--chr1-col 1 --from1-col 2 --to1-col 3 '
        '--chr2-col 4 --from2-col 5 --to2-col 6 '
        '--output-file {output} {input}'


rule zoomify_q:
    input:
        '{group}/{group}.Q.cool'
    output:
        '{group}/{group}.Q.mcool'
    threads:
        1
    shell:
        'cooler zoomify {input}'


rule call_loop:
    input:
        '{group}/{group}.Q.cool',
        '{group}/{group}.E.cool',
        '{group}/{group}.E2.cool',
        '{group}/{group}.T.cool',
        '{group}/{group}.T2.cool'
    output:
        '{group}/{group}.loop_info.hdf',
        '{group}/{group}.loop.bedpe',
        temp('{group}/{group}.scloop.bedpe'),
        temp('{group}/{group}.bkloop.bedpe'),
        '{group}/{group}.loop_summit.bedpe',
    params:
        prefix='{group}/{group}'
    threads:
        1
    shell:
        'hic-internal call-loop '
        '--group_prefix {wildcards.group}/{wildcards.group} '
        '--resolution {resolution} '
        '--output_prefix {params.prefix} '
        '--thres_bl 1.33 '
        '--thres_donut 1.33 '
        '--thres_h 1.2 '
        '--thres_v 1.2 '
        '--fdr_thres 0.1 '
        '--dist_thres 20000 '
        '--size_thres 1'


# merge group chunk dirs into a single scool
input_flag = f'{output_dir}/chunk_finished'
rule merge_chunks:
    input:
        # generated by check_chunk_dir_finish, indicates all chunks are completed
        input_flag
    output:
        temp('{group}/{group}.Q.cool'),
        '{group}/{group}.E.cool',
        '{group}/{group}.E2.cool',
        '{group}/{group}.T.cool',
        '{group}/{group}.T2.cool'
    threads:
        5
    shell:
        'hic-internal merge-group-chunks '
        '--chrom_size_path {chrom_size_path} '
        '--resolution {resolution} '
        '--group {wildcards.group} '
        '--output_dir {output_dir} '

