


[opticalPoints_interp, OT_ts, emPointsFirstSensor_interp, EM_ts, realshift_nano] = interpolate_and_computeTimeShift(file_path, file_prefixOT, file_prefixEMT, datafreq)

%% averaging to find Y
Y_all = zeros(4,4,numPts);
for i = 1:numPts
    Y_all(:,:,i) = H_EMT_to_EMCS(:,:,i) * H_OT_to_EMT * H_OCS_to_OT(:,:,i);
end

Y_tmp = mean(Y_all,3);
Y(:,:) = Y_tmp(:,:,1);

%% 2013_06_04
% cd '.\apps'
path = '..\..\measurements\06.04_Measurements\';
otfile = 'cont_OpticalTracking';
emfile = 'cont_EMTracking';
test=interpolate_and_computeTimeShift(path,otfile,emfile,100);

%% 2013_06_07
% read measurements form disc
[dataOT, dataEMT] = read_TrackingFusion_files;

% transform to homogenic 4x4 matrices
H_OT_to_OCS_cell = trackingdata_to_matrices(dataOT);
H_EMT_to_EMCS_cell = trackingdata_to_matrices(dataEMT);

% plot locations
EMCS_plot_handle = Plot_points(H_EMT_to_EMCS_cell);
OCS_plot_handle = Plot_points(H_OT_to_OCS_cell);

% get Y 
Y = polaris_to_aurora([], [], dataOT, dataEMT);

% transform OT to EMCS coordinates
numOTpoints = size(H_OT_to_OCS_cell{1},3);
for i = 1:numOTpoints
    %optical
    H_OT_to_EMCS_cell{1}(:,:,i) = Y*H_OT_to_OCS_cell{1}(:,:,i);
end

% plot ot frame into EMCS plot
Plot_points(H_OT_to_EMCS_cell, EMCS_plot_handle)