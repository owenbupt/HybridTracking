% function [opticalPoints_interp, OT_ts, emPointsFirstSensor_interp, EM_ts, realshift_nano] = interpolate_and_computeTimeShift(file_path, file_prefixOT, file_prefixEMT, datafreq)

%this script computes the time shift between the optical and electromagnetic
%points. The file path should contain
%some files starting with 'OpticalTracking' and 'EMTracking', each
%containing several measurements of one position in order to have the
%correct transformation between the two coordinate systems. Additionally,
%there should be two files of a continuous measurement, starting with
%'cont_OpticalTracking_1' and 'cont_EMTracking_1'. After an interpolation
%step in order to have measurements at the same points in time these data is
%used to find out how much the data of the optical tracking system has to
%be shifted in time in order to be as good as possible aligned with the
%electromagnetic tracking points. The euclidean distance between respective
%point couples (couples with the same time stamp, adding a timeshift delta 
%to the timeshift of the optical tracking points) is minimized using the 
%function timeshiftfunction2.m.

%% definitions
close all, clear all;
clc;

pathGeneral = fileparts(fileparts(fileparts(pwd)));
file_path = [pathGeneral filesep 'measurements' filesep '05.29 Measurements' filesep];
%file_path = '.\timeshift\05.29 Measurements\';
file_prefixOT = 'cont_OpticalTracking_1';
file_prefixEMT = 'cont_EMTracking_1';
dOT = dir([file_path file_prefixOT '*']);
dEM = dir([file_path file_prefixEMT '*']);

numFiles = numel(dOT);
namesOT = sort({dOT(:).name});
namesEM = sort({dEM(:).name});
    
%dataOT = cell(1, numel(dOT));
%dataEM = cell(1, numel(dEM));
delimiter = ' ';
formatSpecOT = '%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';
formatSpecEM = '%s%s%s%s%s%s%s%s%s%s%s%s%s%[^\n\r]';

numPointsOT = 0;
numPointsEM = 0;
amountErrorPointsOT = 0;
amountErrorPointsEM = 0;
goodOTPts = [];
goodEMPts = [];


%pointsToTake = 100;

% take all points in the file
pointsToTake = 0; 

% define desired polling frequency
datafreq = 25; % 25 Hz
% calc sample period
dataperiod = 1/datafreq;
%in nanoseconds
dataperiodnano = dataperiod * 1e9;
% now the samples can have a maximum temporal resolution of 'datafreq'
% hertz
timeStampDivision = dataperiodnano;

%% loader and parser
for j = 1:numFiles %equals amount of OT-files (each file represents several measurements of one point, in 04.23 set 2 we have 6 points)
    % LOAD OT
    fileIDOT = fopen([file_path namesOT{j}],'r');
    dataArrayOT = textscan(fileIDOT, formatSpecOT, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true,  'ReturnOnError', false);
    TempPosition = [str2double(dataArrayOT{1,2}), str2double(dataArrayOT{1,3}), str2double(dataArrayOT{1,4})];
    TempOrient = [str2double(dataArrayOT{1,6}), str2double(dataArrayOT{1,7}), str2double(dataArrayOT{1,8}), str2double(dataArrayOT{1,9})];
    TimeStampOT = str2double(dataArrayOT{1,11});
    TimeStampOT = round(TimeStampOT / timeStampDivision);
    % Stores OT in the cell
    numPointsOT = size(TempPosition,1)
    if pointsToTake~=0&&numPointsOT>pointsToTake
        numPointsOT=pointsToTake;
    end
    for k = 1:numPointsOT
         if (TempPosition(k,1) < 10000 && TempPosition(k,1) > -10000  && TempPosition(k,2) < 10000 && TempPosition(k,2) > -10000  && TempPosition(k,3) < 10000 && TempPosition(k,3) > -10000)
             dataOT{k-amountErrorPointsOT}.position=TempPosition(k,:);
             dataOT{k-amountErrorPointsOT}.orientation=TempOrient(k,:);
             dataOT{k-amountErrorPointsOT}.TimeStamp=TimeStampOT(k);
             goodOTPts = [goodOTPts k];
         else
             amountErrorPointsOT = amountErrorPointsOT + 1;
         end
    end
    
   % clear TempPosition dataArrayOT TempOrient fileIDOT;
   
    % LOAD EM
    fileIDEM = fopen([file_path namesEM{j}],'r');
    dataArrayEM = textscan(fileIDEM, formatSpecEM, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true,  'ReturnOnError', false);
    TempPosition= [str2double(dataArrayEM{1,4}), str2double(dataArrayEM{1,5}), str2double(dataArrayEM{1,6})];
    TempOrient = [str2double(dataArrayEM{1,8}), str2double(dataArrayEM{1,9}), str2double(dataArrayEM{1,10}), str2double(dataArrayEM{1,11})];
    % Split the raw data according to the 3 sensors
    TimeStampEM = str2double(dataArrayEM{1,13});
    TimeStampEM = round(TimeStampEM / timeStampDivision);
    index0 = 1; index1 = 1; index2 = 1;
    for i = 1:size(TempPosition)
        switch str2double(dataArrayEM{1,2}(i));
            case 0
                TempPositionFirstSensor(index0,:) = TempPosition(i,:);
                TempOrientFirstSensor(index0,:) = TempOrient(i,:);
                TempTimeFirstSensor(index0) = TimeStampEM(i);
                index0 = index0 + 1;
        end
    end
       
    % Stores EM in the cell
    numPointsEM = size(TempPositionFirstSensor,1)
    if pointsToTake~=0&&numPointsEM>pointsToTake
        numPointsEM=pointsToTake;
    end
    for k = 1:numPointsEM
        if (TempPositionFirstSensor(k,1) < 10000 && TempPositionFirstSensor(k,1) > -10000  && TempPositionFirstSensor(k,2) < 10000 && TempPositionFirstSensor(k,2) > -10000  && TempPositionFirstSensor(k,3) < 10000 && TempPositionFirstSensor(k,3) > -10000)
            dataEM{k-amountErrorPointsEM}.FirstSensor.position=TempPositionFirstSensor(k,:);
            dataEM{k-amountErrorPointsEM}.FirstSensor.orientation=TempOrientFirstSensor(k,:);
            dataEM{k-amountErrorPointsEM}.FirstSensor.TimeStamp=TempTimeFirstSensor(k);
            goodEMPts = [goodEMPts k];
        else
            amountErrorPointsEM = amountErrorPointsEM + 1;
        end
    end

%we just have 1 sensor    

end % Loader



%% Cells to Point-arrays
% Saves the computed points in matrices
%usually
numPointsEM = numPointsEM - amountErrorPointsEM;
numPointsOT = numPointsOT - amountErrorPointsOT;

% if(numPointsOT < numPointsEM)
%     numPoints = numPointsOT;
% else
%     numPoints = numPointsEM;
% end

ts_fighandle = figure;
%plot measurements on time axis - should be alternating then
for k = 1:numPointsOT
  plot(k, dataOT{k}.TimeStamp, 'bx');
  hold on
end
for k = 1:numPointsEM
  plot(k, dataEM{k}.FirstSensor.TimeStamp, 'rx');
  hold on
end


% I want to map the optical points to where their respective EM Tracker
% should have been...
% that is: ET_from_OT_in_EMCS = Y * OT_to_OCS * EMT_to_OT;

[H_OT_to_EMT]=[ -0.8552    0.0758   -0.5128  -10.6194
                -0.3838    0.5723    0.7247   -1.9664
                 0.3483    0.8165   -0.4603  -49.3463
                 0         0         0    1.0000];
H_EMT_to_OT = inv(H_OT_to_EMT);
[H_OT_to_OCS_cell, H_OCS_to_OT_cell] = trackingdata_to_matrices(permute(dataOT,[2 1]), 'CppCodeQuat');
H_OT_to_OCS = H_OT_to_OCS_cell{1};

dataEMnew = cell(size(dataEM, 2), 1);
for i = 1:size(dataEM, 2)
    dataEMnew{i}.position = dataEM{i}.FirstSensor.position;
    dataEMnew{i}.orientation = dataEM{i}.FirstSensor.orientation;
end

[H_EMT_to_EMCS_cell] = trackingdata_to_matrices(dataEMnew, 'CppCodeQuat');
H_EMT_to_EMCS = H_EMT_to_EMCS_cell{1};


Y = polaris_to_aurora('..\measurements\testmfrom_NDItrack', H_OT_to_EMT);

for i = 1:numPointsOT
    H_ET_from_OT_in_EMCS(:,:,i) = Y * H_OT_to_OCS(:,:,i) * H_EMT_to_OT;
    transformationOpticalToFirstSensor{i}.R= H_ET_from_OT_in_EMCS(1:3,1:3, i);
    transformationOpticalToFirstSensor{i}.t = H_ET_from_OT_in_EMCS(1:3,4, i);
end

dataOTToEMOne = dataOT;

figure
for i = 1:numPointsOT;
    pointvector = [0;0;0];
    pointvector = transformationOpticalToFirstSensor{i}.R * pointvector + transformationOpticalToFirstSensor{i}.t;
    dataOTToEMOne{i}.position(1) = pointvector(1);
    dataOTToEMOne{i}.position(2) = pointvector(2);
    dataOTToEMOne{i}.position(3) = pointvector(3);
    plot3(dataOTToEMOne{i}.position(1), dataOTToEMOne{i}.position(2), dataOTToEMOne{i}.position(3), 'bx')
    box on;
    grid on;
    hold on
end
for i = 1:numPointsEM
    plot3(dataEM{i}.FirstSensor.position(1), dataEM{i}.FirstSensor.position(2), dataEM{i}.FirstSensor.position(3), 'ro');
    hold on;
end

axis vis3d image

%so since we do not always know the correct Y, We add an ICP afterwards
opticalPoints = zeros(3, numPointsOT);
emPointsFirstSensor = zeros(3,numPointsEM);
for i = 1:numPointsOT
    opticalPoints(:,i) = dataOTToEMOne{i}.position;
end
for i = 1:numPointsEM
    emPointsFirstSensor(:,i) = dataEM{i}.FirstSensor.position;
end

% V=F(X);
% Vq = INTERP1(X,V,Xq)
opticalPoints_interp(1,:) = interp1(TimeStampOT(goodOTPts), opticalPoints(1,:),TimeStampOT(1):TimeStampOT(end));
opticalPoints_interp(2,:) = interp1(TimeStampOT(goodOTPts), opticalPoints(2,:),TimeStampOT(1):TimeStampOT(end));
opticalPoints_interp(3,:) = interp1(TimeStampOT(goodOTPts), opticalPoints(3,:),TimeStampOT(1):TimeStampOT(end));

emPointsFirstSensor_interp(1,:) = interp1(TimeStampEM(goodEMPts), emPointsFirstSensor(1,:),TimeStampOT(1):TimeStampOT(end));
emPointsFirstSensor_interp(2,:) = interp1(TimeStampEM(goodEMPts), emPointsFirstSensor(2,:),TimeStampOT(1):TimeStampOT(end));
emPointsFirstSensor_interp(3,:) = interp1(TimeStampEM(goodEMPts), emPointsFirstSensor(3,:),TimeStampOT(1):TimeStampOT(end));

% Obtains transformation matrix
transformationOpticalToFirstSensor = absor(opticalPoints_interp,emPointsFirstSensor_interp);

finalICP_fighandle = figure;
for i = 1:numPointsOT;
    pointvector = opticalPoints(:,i);
    pointvector = transformationOpticalToFirstSensor.R * pointvector + transformationOpticalToFirstSensor.t;
    opticalPoints(:,i) = pointvector;
    dataOTToEMOne{i}.position(1) = pointvector(1);
    dataOTToEMOne{i}.position(2) = pointvector(2);
    dataOTToEMOne{i}.position(3) = pointvector(3);
    plot3(dataOTToEMOne{i}.position(1), dataOTToEMOne{i}.position(2), dataOTToEMOne{i}.position(3), 'bx')
    box on;
    grid on;
    hold on
end
for i = 1:numPointsEM
    plot3(dataEM{i}.FirstSensor.position(1), dataEM{i}.FirstSensor.position(2), dataEM{i}.FirstSensor.position(3), 'ro');
    hold on;
end

axis vis3d image
%discretized

% determine 3D positions of both sensors (dataEM and dataOTToEMOne) for
% each time step, we only want the times where we have data of both
% tracking devices
minTSOT = dataOTToEMOne{1}.TimeStamp;
maxTSOT = dataOTToEMOne{numPointsOT}.TimeStamp;
minTSEM = dataEM{1}.FirstSensor.TimeStamp;
maxTSEM = dataEM{numPointsEM}.FirstSensor.TimeStamp;


opticalPoints_interp = [];

opticalPoints_interp(1,:) = interp1(TimeStampOT(goodOTPts), opticalPoints(1,:),TimeStampOT(1):TimeStampOT(end));
opticalPoints_interp(2,:) = interp1(TimeStampOT(goodOTPts), opticalPoints(2,:),TimeStampOT(1):TimeStampOT(end));
opticalPoints_interp(3,:) = interp1(TimeStampOT(goodOTPts), opticalPoints(3,:),TimeStampOT(1):TimeStampOT(end));

allOT = cell(size(opticalPoints_interp, 2),1);
counterOT = size(opticalPoints_interp, 2);

OT_ts = TimeStampOT(1):TimeStampOT(end);

for i = 1:size(opticalPoints_interp, 2)
    allOT{i}.position(1) = opticalPoints_interp(1,i);
    allOT{i}.position(2) = opticalPoints_interp(2,i);
    allOT{i}.position(3) = opticalPoints_interp(3,i);
    
    allOT{i}.TimeStamp = OT_ts(i);
end

emPointsFirstSensor_interp = [];

emPointsFirstSensor_interp(1,:) = interp1(TimeStampEM(goodEMPts), emPointsFirstSensor(1,:),TimeStampEM(1):TimeStampEM(end));
emPointsFirstSensor_interp(2,:) = interp1(TimeStampEM(goodEMPts), emPointsFirstSensor(2,:),TimeStampEM(1):TimeStampEM(end));
emPointsFirstSensor_interp(3,:) = interp1(TimeStampEM(goodEMPts), emPointsFirstSensor(3,:),TimeStampEM(1):TimeStampEM(end));

allEM = cell(size(emPointsFirstSensor_interp, 2),1);
counterEM = size(emPointsFirstSensor_interp, 2);

EM_ts = TimeStampEM(1):TimeStampEM(end);

for i = 1:size(emPointsFirstSensor_interp, 2)
    allEM{i}.position(1) = emPointsFirstSensor_interp(1,i);
    allEM{i}.position(2) = emPointsFirstSensor_interp(2,i);
    allEM{i}.position(3) = emPointsFirstSensor_interp(3,i);
    
    allEM{i}.TimeStamp = EM_ts(i);
end

% plot successful interpolation
figure
for i = 1:size(emPointsFirstSensor_interp, 2)
    plot3(allEM{i}.position(1), allEM{i}.position(2), allEM{i}.position(3), 'ro');
    hold on;
    box on;
    grid on;
end
for i = 1:size(opticalPoints_interp, 2)
    plot3(allOT{i}.position(1), allOT{i}.position(2), allOT{i}.position(3), 'bx');
    hold on;
end

axis vis3d image

%Caution: 2 different clocks are running or not? min and max can belong to
%different initial offsets. #resolved
% --> no, it is the same clock running, namely the system clock of campcom
% server

if minTSOT > minTSEM
    min = minTSOT;
else
    min = minTSEM;
end
if maxTSOT < maxTSEM
    max = maxTSOT;
else
    max = maxTSEM;
end

% determine boundaries
minEM=1;
if min~=minTSEM
    for i = 1:counterEM-1
        if allEM{i}.TimeStamp == min
            minEM=i;
        end
    end
end
minOT=1;
if min~=minTSOT
    for i = 1:counterOT-1
        if allOT{i}.TimeStamp == min
            minOT=i;
        end
    end
end
maxEM=counterEM-1;
if max~=maxTSEM
    for i = 1:counterEM-1
        if allEM{i}.TimeStamp == max
            maxEM=i;
        end
    end
end
maxOT=counterOT-1;
if max~=maxTSOT
    for i = 1:counterOT-1
        if allOT{i}.TimeStamp == max
            maxOT=i;
        end
    end
end   

discrete=0;
if discrete==1
    %for i = 1:counterEM-1
    for i = minEM:maxEM
        tsdiff{i} = 0;
        distancemin{i} = 100000;
        for j = i-100:i+100<f
            if j > 0 && j < (counterOT-1)
            %for j = minOT:maxOT
                distance = sqrt( (allEM{i}.position(1) - allOT{j}.position(1))^2 + (allEM{i}.position(2) - allOT{j}.position(2))^2 + (allEM{i}.position(3) - allOT{j}.position(3))^2 ); 
                if distance < distancemin{i}
                    distancemin{i} = distance;
                    tsdiff{i} = allEM{i}.TimeStamp - allOT{j}.TimeStamp;
                end
            end
        end
    end

    figure
    for i = 1:counterEM-1
        plot(i, tsdiff{i}, 'bx');    
        hold on
    end
else
    counter=1;
    for i = minOT:maxOT
        OTtoUse{counter} = allOT{i};
        counter= counter+1;
    end
    counter = 1;
    for i = minEM:maxEM
        EMtoUse{counter} = allEM{i};
        counter= counter+1;
    end
    
    interOptPos = OTtoUse;
    % do linear interpolation for optical sensor
    % determine deltaT by minimizing the sum!
    %deltaT = -106276318 / timeStampDivision;
    deltaT = -200;
    %interOptPos = dataOT;
    %fh = @(deltaT) timeshiftfunction(deltaT, EMtoUse, OTtoUse, interOptPos, maxEM-minEM);
    fh = @(deltaT) timeshiftfunction2(deltaT, EMtoUse, OTtoUse, maxEM-minEM);


    opt = optimset('Display','iter','TolX',1.0e-005,'MaxIter',100);
    [deltaT, meanEuclideanDistance,exitflag] = fminsearch(fh,deltaT,opt);

    deltaT
    meanEuclideanDistance
    realshift= deltaT*timeStampDivision
    
    realshift_nano = realshift;
end


