function simulate_realtime_plot(file_path, file_prefixOT, file_prefixEMT)
% simulate_realtime_plot simulates data being read in by TrackingFusion.cpp
% and being sent to a matlab plot to show the concept and fps performance.
% Also the Environment (Polaris and Aurora device) is plotted.

% read measurements form disc
[dataOT, dataEMT] = read_TrackingFusion_files(file_path, file_prefixOT, file_prefixEMT);
numOTPts = size(dataOT,1);
numEMPts = size(dataEMT,1);
numEMSensors = size(dataEMT,2);

% sort timestamps
TS_OT = zeros(numOTPts,1);
for i = 1:numOTPts
    TS_OT(i,1)=dataOT{i}.TimeStamp;
    TS_OT(i,2)=1;
end
TS_EM = zeros(numEMPts,numEMSensors);
for i = 1:numEMPts
    for j = 1:numEMSensors
        if ~isempty(dataEMT{i,j})
            TS_EM(i,j*2-1)=dataEMT{i,j}.TimeStamp;
            TS_EM(i,j*2)=j+1;
        end
    end
end
%  rearrange EM timestamps
% TS_EM_new = zeros(numEMPts*numEMSensors,2);
TS_EM_new = [];
index_of_TS_EM_new = 0;
for j = 1:numEMSensors
    index_of_last_available_pt = find(TS_EM(:,2*j), 1, 'last');
    TS_EM_new = [TS_EM_new; TS_EM(1:index_of_last_available_pt,(2*j-1):2*j)];
%     start_index = index_of_TS_EM_new+1;
%     index_of_TS_EM_new = index_of_TS_EM_new + index_of_last_available_pt - 1;
%     TS_EM_new(start_index:index_of_TS_EM_new,:)=TS_EM(1:index_of_last_available_pt,(2*j-1):2*j);
end
index_of_last_available_pt = find(TS_EM_new(:,1), 1, 'last');
TS_EM_new = TS_EM_new(1:index_of_last_available_pt,:);
TS_all = [TS_OT; TS_EM_new];
[TS_all(:, 1), sort_indexes] = sort(TS_all(:, 1));
TS_all(:, 2) = TS_all(sort_indexes,2);


%get Y
%this is debug_apps\wip_Felix.m
currentPath = which('wip_Felix.m');
pathGeneral = fileparts(fileparts(fileparts(currentPath)));
path = [pathGeneral filesep 'measurements' filesep '06.07_Measurements'];
Y = polaris_to_aurora(path);

% transform to homogenic 4x4 matrices
H_OT_to_OCS_cell = trackingdata_to_matrices(dataOT, 'CppCodeQuat');
H_EMT_to_EMCS_cell = trackingdata_to_matrices(dataEMT, 'CppCodeQuat');

% transform OT to EMCS coordinates
numOTpoints = size(H_OT_to_OCS_cell{1},3);
for i = 1:numOTpoints
    H_OT_to_EMCS_cell{1}(:,:,i) = Y*H_OT_to_OCS_cell{1}(:,:,i);
end

% plot environment
realtime_plot_figure = figure('Position', get(0,'ScreenSize'));
plotEnvironment(realtime_plot_figure, [], Y);

view(3)
% go through index column, plot points of given source
c = colormap('lines');
ot_ind = 1;
emt1_ind = 1;
emt2_ind = 1;
emt3_ind = 1;

for SensorIndex = TS_all(:, 2)'
    hold on
    switch SensorIndex;
        case 1 %OT sensor
            point = H_OT_to_EMCS_cell{1}(1:3,4,ot_ind);
            if exist('otObj', 'var'), delete(otObj); end
            otObj = plot3(point(1), point(2), point(3), 'o', 'Color', c(1,:) );
            ot_ind = ot_ind+1;
        case 2 %EMT1 sensor
            point = H_EMT_to_EMCS_cell{SensorIndex-1}(1:3,4,emt1_ind);
            if exist('emt1Obj', 'var'), delete(emt1Obj); delete(cylinderObj); end
            emt1Obj = plot3(point(1), point(2), point(3), 'x', 'Color', c(2,:) );
            % plot a nice cylinder depicting the tool
            cylinderObj = Plot_cylinder(H_EMT_to_EMCS_cell{SensorIndex-1}(:,:,emt1_ind));
            
            emt1_ind = emt1_ind+1;
        case 3 %EMT2 sensor
            point = H_EMT_to_EMCS_cell{SensorIndex-1}(1:3,4,emt2_ind);
            if exist('emt2Obj', 'var'), delete(emt2Obj); end
            emt2Obj = plot3(point(1), point(2), point(3), 'x', 'Color', c(3,:) );
            emt2_ind = emt2_ind+1;
        case 4 %EMT3 sensor
            point = H_EMT_to_EMCS_cell{SensorIndex-1}(1:3,4,emt3_ind);
            if exist('emt3Obj', 'var'), delete(emt3Obj); end
            emt3Obj = plot3(point(1), point(2), point(3), 'x', 'Color', c(4,:) );
            emt3_ind = emt3_ind+1;
    end
    hold off
    drawnow
%     pause
end

end