% This script generates 66-region subcortical atlas, combining
% 1) 54-region scale-IV subcortical atlas from Tian et al., 2020, Nat Neuro,
% 2) 10-region multi-domain task battery cerebellum atlas from King et al., 2019, Nat Neuro,
% 3) PAG from Roy et al., 2014, Nat Neuro
% 4) Brainstem from Beissner et al., 2014, Neuroimage,

gitdir = '/Volumes/homeo/github';
spmdir = '/Volumes/homeo/dropbox/resources/spm12';
addpath(genpath(spmdir));

atlas_subcortex = spm_read_vols(spm_vol(fullfile(gitdir, 'subcortex/Group-Parcellation/3T/Subcortex-Only/Tian_Subcortex_S4_3T.nii')));

atlas_cerebellum_orig = fullfile(gitdir, 'cerebellar_atlases/King_2019/atl-MDTB10_space-MNI_dseg.nii');
tmpdir = tempname(tempdir); mkdir(tmpdir);
atlas_cerebellum = fullfile(tmpdir, 'atl-MDTB10_space-MNI_dseg.nii');
system(sprintf('export FSLOUTPUTTYPE=NIFTI; fslmaths %s %s -odt float', ...
    atlas_cerebellum_orig, atlas_cerebellum));
system(sprintf('export FSLOUTPUTTYPE=NIFTI; fslmaths %s %s -odt float', ...
    '$FSLDIR/data/standard/MNI152_T1_2mm_brain.nii.gz', fullfile(tmpdir, 'MNI.nii')));

spmopts = struct('prefix', '', 'mask', 0, 'interp', 0, 'wrap', [0 0 0], 'which', [1 0]);
spm_reslice({fullfile(tmpdir, 'MNI.nii'), atlas_cerebellum}, spmopts);
atlas_cerebellum = spm_read_vols(spm_vol(atlas_cerebellum));

atlas_pag = spm_read_vols(spm_vol(fullfile(gitdir, 'cocoanlab/cocoanCORE/Canonical_brains/Roy_2014_PAG_mask_2mm_MNI.nii')));

atlas_brainstem = spm_read_vols(spm_vol(fullfile(gitdir, 'cocoanlab/cocoanCORE/Canonical_brains/Beissner_2014_brainstem_mask_2mm_MNI.nii')));

atlas_combined = atlas_subcortex;
atlas_combined(atlas_combined == 0 & atlas_cerebellum > 0) = ...
    atlas_cerebellum(atlas_combined == 0 & atlas_cerebellum > 0) + max(atlas_combined, [], 1:3);
atlas_combined(atlas_combined == 0 & atlas_pag > 0) = ...
    atlas_pag(atlas_combined == 0 & atlas_pag > 0) + max(atlas_combined, [], 1:3);
atlas_combined(atlas_combined == 0 & atlas_brainstem > 0) = ...
    atlas_brainstem(atlas_combined == 0 & atlas_brainstem > 0) + max(atlas_combined, [], 1:3);

atlas_combined_vol = spm_vol(fullfile(gitdir, 'cocoanlab/cocoanCORE/Canonical_brains/Roy_2014_PAG_mask_2mm_MNI.nii'));
atlas_combined_vol.fname = fullfile(gitdir, 'cocoanlab/cocoanCORE/Canonical_brains/subcortex_comb/subcortex_comb_r66.nii');
spm_write_vol(atlas_combined_vol, atlas_combined);

rmpath(genpath(spmdir));

subcortex_comb_r66 = struct;
subcortex_comb_r66.dat(:,1) = 1:max(atlas_combined,[],1:3);
subcortex_comb_r66.descrip = {'Column 1: Original mask value, Column 2: Gross-anatomical labels, Column 3: Laterality', ...
    '1: Thalamus, 2: Hippocampus/Amygdala, 3: Basal ganglia, 4: Cerebellum, 5: Brainstem', ...
    'Laterality. -1: Left, 1: Right, 0: No laterality'};
subcortex_comb_r66.names = [importdata(fullfile(gitdir, 'subcortex/Group-Parcellation/3T/Subcortex-Only/Tian_Subcortex_S4_3T_label.txt')); ...
    strcat({'Cb_'}, split(deblank(sprintf('%.2d\n',1:10)))); {'PAG'; 'Brainstem'}];
subcortex_comb_r66.dat(:,2) = sum([contains(subcortex_comb_r66.names, 'THA'), ...
    contains(subcortex_comb_r66.names, {'HIP', 'AMY'}), ...
    contains(subcortex_comb_r66.names, {'CAU', 'PUT', 'NAc', 'GP'}), ...
    contains(subcortex_comb_r66.names, {'Cb'}), ...
    contains(subcortex_comb_r66.names, {'PAG'; 'Brainstem'})] .* (1:5), 2);
subcortex_comb_r66.dat(:,3) = sum([contains(subcortex_comb_r66.names, {'-lh', 'Cb_01', 'Cb_05', 'Cb_07'}), ...
    contains(subcortex_comb_r66.names, {'-rh', 'Cb_02', 'Cb_06', 'Cb_08', 'Cb_09'})] .* [-1 1], 2);
save(fullfile(gitdir, 'cocoanlab/cocoanCORE/Canonical_brains/subcortex_comb/subcortex_comb_r66_labels.mat'), 'subcortex_comb_r66');

