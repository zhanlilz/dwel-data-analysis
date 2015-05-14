% CalcPtsNDI.m
% 1. calculate difference index for each point in 1064 and 1548 overlapping
% point cloud. 
% 2. Create a color-composite point cloud with 1548 as red, 1064 as green,
% and dark as blue. 
% Zhan Li, zhanli86@bu.edu
% Created: 2013
% Last modified: 2014-5-29

clear;
% parameters to input
NDI_threshold = 0.225;
% lower and upper limit of intensity to scale the color of 1064 (green) and
% 1548 (red).
% if empty [] given, actual minimum/maximum of 1064/1548 intensity will be
% used to scale the color.
minI1064 = 0; 
maxI1064 = 3000;
minI1548 = 0;
maxI1548 = 3000;

% % files to input
% ptsfile1064 = '/home/zhanli/Workspace/data/dwel-processing/brisbane2013-kara01/brisbane2013-kara01-points/oldpointextraction/July31_Kara1_N_1064_Cube_NadirCorrect_Aligned_nu_basefix_satfix_pfilter_b32r04_at_project_ptcl_points.txt';
% ptsfile1548 = '/home/zhanli/Workspace/data/dwel-processing/brisbane2013-kara01/brisbane2013-kara01-points/oldpointextraction/July31_Kara1_N_1548_Cube_NadirCorrect_Aligned_nu_basefix_satfix_pfilter_b32r04_at_project_ptcl_points.txt';
% % files to output
% ptsndifile = ['/home/zhanli/Workspace/data/dwel-processing/brisbane2013-kara01/brisbane2013-kara01-points/oldpointextraction/July31_Kara1_N_Cube_NadirCorrect_Aligned_nu_basefix_satfix_pfilter_b32r04_at_project_ptcl_points_ndirgb_', num2str(NDI_threshold), '.txt'];
% ptsccfile = '/home/zhanli/Workspace/data/dwel-processing/brisbane2013-kara01/brisbane2013-kara01-points/oldpointextraction/July31_Kara1_N_Cube_NadirCorrect_Aligned_nu_basefix_satfix_pfilter_b32r04_at_project_ptcl_points_rgbcc.txt';

% files to input
ptsfile1064 = '/home/zhanli/Workspace/data/dwel-processing/hfhd20140919/hfhd20140919-ptcl/HFHD_20140919_C_1064_cube_bsfix_pxc_update_atp4_ptcl_points.txt';
ptsfile1548 = '/home/zhanli/Workspace/data/dwel-processing/hfhd20140919/hfhd20140919-ptcl/HFHD_20140919_C_1548_cube_bsfix_pxc_update_atp4_ptcl_points.txt';
% files to output
ptsndifile = ['/home/zhanli/Workspace/data/dwel-processing/hfhd20140919/' ...
              'hfhd20140919-ptcl/HFHD_20140919_C_cube_bsfix_pxc_update_atp4_ptcl_points_ndirgb_', num2str(NDI_threshold), '.txt'];
ptsccfile = ['/home/zhanli/Workspace/data/dwel-processing/hfhd20140919/' ...
             'hfhd20140919-ptcl/HFHD_20140919_C_cube_bsfix_pxc_update_atp4_ptcl_points_rgbcc.txt'];

% X,Y,Z,d_I,Return_Number,Number_of_Returns,Shot_Number,Run_Number,range,theta,phi,Sample,Line,Band
% read point cloud data generated by EVI/DWEL programs.
fid = fopen(ptsfile1064, 'r');
data = textscan(fid, repmat('%f ', 1, 15), 'HeaderLines', 3, 'Delimiter', ',');
fclose(fid);
pts1064 = cell2mat(data);
fid = fopen(ptsfile1548, 'r');
data = textscan(fid, repmat('%f ', 1, 15), 'HeaderLines', 3, 'Delimiter', ',');
fclose(fid);
pts1548 = cell2mat(data);
clear data;

% suppress all negative intensity to zero
tmplogic = pts1064(:, 4)<0;
pts1064(tmplogic, 4)=0;
tmplogic = pts1548(:, 4)<0;
pts1548(tmplogic, 4)=0;
% remove all zero locations
tmplogic = pts1064(:, 1)==0 & pts1064(:,2)==0 & pts1064(:,3)==0;
pts1064(tmplogic, :) = [];
tmplogic = pts1548(:,1)==0 & pts1548(:,2)==0 & pts1548(:,3)==0;
pts1548(tmplogic, :) = [];

% find the common points between 1064 and 1548 by checking their return
% numbers (1st or 2nd or ... return) and their angular positions. 
% If the three fields are the same, we think there is common point pair.
% !!! This might NOT BE TRUE, e.g. when two peaks are extracted from the
% 1548 nm while only one peak from the 1064 nm. !!!
[tmp, i1064, i1548] = intersect([pts1064(:, 5:6), pts1064(:,13:14)], [pts1548(:, 5:6), pts1548(:,13:14)], 'rows');

% NDI of each common point
pts_ndi = (pts1064(i1064, 4)-pts1548(i1548, 4))./(pts1064(i1064, 4)+pts1548(i1548, 4));
pts_mean = (pts1064(i1064, 1:3)+pts1548(i1548, 1:3))/2;

% =========================================================
% temporarily invert the sign of x coordinates to match CBL
% pts_mean(:,1) = -1*pts_mean(:,1);
% =========================================================

rgb = zeros(length(pts_ndi), 3);
% classification with NDI
% branches
rgb(pts_ndi < NDI_threshold, 1) = 255;
% leaves
rgb(pts_ndi >= NDI_threshold, 2) = 255;

fid = fopen(ptsndifile, 'w');
infid = fopen(ptsfile1064, 'r');
linestr = fgetl(infid);
fprintf(fid, '%s; NDI classification, NDI_thresh=%f\n', linestr, NDI_threshold);
linestr = fgetl(infid);
fprintf(fid, '%s\n', linestr);
fclose(infid);
fprintf(fid, 'X,Y,Z,d_I,R,G,B,range,theta,phi,number_of_returns,sample,line\n');
fprintf(fid, '%.3f,%.3f,%.3f,%.3f,%d,%d,%d,%.3f,%.3f,%.3f,%d,%d,%d\n', ([pts_mean, pts_ndi, rgb, pts1064(i1064,9:11), pts1064(i1064,6), pts1064(i1064,12:13)])');
fclose(fid);

if isempty(minI1064)
    minI1064 = min(pts1064(:,4));
end
if isempty(maxI1064)
    maxI1064 = max(pts1064(:,4));
end
NormIntensity1064 = (pts1064(:,4)-minI1064)/(maxI1064-minI1064);
NormIntensity1064(NormIntensity1064 > 1) = 1;
if isempty(minI1548)
    minI1548 = min(pts1548(:,4));
end
if isempty(maxI1548)
    maxI1548 = max(pts1548(:,4));
end
NormIntensity1548 = (pts1548(:,4)-minI1548)/(maxI1548-minI1548);
NormIntensity1548(NormIntensity1548 > 1) = 1;
rgbcc = zeros(length(pts_ndi), 3);
rgbcc(:, 1) = round(NormIntensity1548(i1548)*255);
rgbcc(:, 2) = round(NormIntensity1064(i1064)*255);
fid = fopen(ptsccfile, 'w');
infid = fopen(ptsfile1064, 'r');
linestr = fgetl(infid);
fprintf(fid, ['%s; color composite, red (1548), green (1064), blue ' ...
              '(dark), min1064=%f, max1064=%f, min1548=%f, max1548=%f\n'], ...
        linestr, minI1064, maxI1064, minI1548, maxI1548);
linestr = fgetl(infid);
fprintf(fid, '%s\n', linestr);
fclose(infid);
fprintf(fid, 'X,Y,Z,d_I,R,G,B\n');
fprintf(fid, '%.3f,%.3f,%.3f,%.3f,%d,%d,%d\n', ([pts_mean, pts_ndi, rgbcc])');
fclose(fid);