function Y = polaris_to_aurora(path, H_OT_to_EMT)
%% data read in
% do preparation
currentPath = which(mfilename);
if ~exist('path', 'var') || isempty(path)
    pathGeneral = fileparts(fileparts(fileparts(currentPath)));
    path = [pathGeneral filesep 'measurements' filesep 'testmfrom_NDItrack'];

end
if ~exist('H_OT_to_EMT', 'var')
    load(which('H_OT_to_EMT.mat'));
end

testrow_name_EMT = 'distorEMT';
testrow_name_OT = 'distorOT';

% get data for hand/eye calib
[data_EMT] = read_NDI_tracking_files(path, testrow_name_EMT);
[data_OT] = read_NDI_tracking_files(path, testrow_name_OT);

%prepare data
numPts = size(data_EMT,1);
numSensors = 2;
mat=cell(1,numSensors);

for j = 1:numSensors
    mat{j} = zeros(4, 4, numPts);
end

for i = 1:numPts

    %insert rotation into homogeneous matrix
    mat{1}(:,:,i) = quat2rot((data_EMT{i,1}.orientation(2:4))');

    mat{2}(:,:,i) = quat2rot((data_OT{i}.orientation(2:4))');

    %add translation
    mat{1}(:,:,i) = transl(data_EMT{i,1}.position') * mat{1}(:,:,i);

    mat{2}(:,:,i) = transl(data_OT{i}.position') * mat{2}(:,:,i);

end

%gHc = tracking_handEyeCalib(bHg, wHc)

% We want to have EMCS as world coordinates. World in Tsai's setup always
% means the grid. I will filp this to match EMT~Cam and OT~Marker.
for i = 1:numPts
    H_EMCS_to_EMT(:,:,i)    = inv(mat{1}(:,:,i)); %(=EMCS_to_EMT)
    H_EMT_to_EMCS(:,:,i)    = mat{1}(:,:,i);
    H_OT_to_OCS(:,:,i)      = mat{2}(:,:,i);      %(=OT_to_OCS)
    H_OCS_to_OT(:,:,i)      = inv(mat{2}(:,:,i));
end

%% averaging to find Y
Y_all = zeros(4,4,numPts);
for i = 1:numPts
    Y_all(:,:,i) = H_EMT_to_EMCS(:,:,i) * H_OT_to_EMT * H_OCS_to_OT(:,:,i);
end

Y_tmp = mean(Y_all,3);
Y(:,:) = Y_tmp(:,:,1);

end