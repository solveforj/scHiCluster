# command time python /gale/ddn/snm3C/humanPFC/code/embed_mergechr.py --embed_list /gale/ddn/snm3C/humanPFC/smoothed_matrix/100kb_resolution/filelist/embedlist_pad1_std1_rp0.5_sqrtvc.txt --outprefix /gale/ddn/snm3C/humanPFC/smoothed_matrix/100kb_resolution/merged/pad1_std1_rp0.5_sqrtvc

import h5py
import argparse
import numpy as np
from sklearn.decomposition import TruncatedSVD

def embed_mergechr(embed_list, outprefix):
	embedlist = np.loadtxt(embed_file, dtype=np.str)[:,0]
	matrix_reduce = np.concatenate([np.load(x) for x in embedlist], axis=1)
	svd = TruncatedSVD(n_components=50, algorithm='arpack')
	matrix_reduce = svd.fit_transform(matrix_reduce)
	matrix_reduce = matrix_reduce / svd.singular_values_
	with h5py.File(f'{outprefix}.svd50.hdf5', 'a') as f:
		tmp = f.create_dataset('data', matrix_reduce.shape, dtype='float32', compression='gzip')
		tmp[()] = matrix_reduce
	return

parser = argparse.ArgumentParser()
parser.add_argument('--embed_list', type=str, default=None, help='Full path of a file containing the full path to dimension reduction files of all chromosomes')
parser.add_argument('--outprefix', type=str, default=None, help='Prefix of final dimension reduction file including directory')
opt = parser.parse_args()

embed_mergechr(opt.embed_list, opt.outprefix)
