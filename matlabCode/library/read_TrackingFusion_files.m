function [dataOT, dataEM] = read_TrackingFusion_files(file_path, file_prefixOT, file_prefixEMT)

% definitions
close all;
% clear all;
% clc;

if ~exist('file_path', 'var')
    % read_TrackingFusion_files should be located in
    % HybridTracking\matlabCode\library\
    pathGeneral = fileparts(fileparts(fileparts(which(mfilename)))); % pathGeneral is HybridTracking\
    file_path = [pathGeneral filesep 'measurements' filesep '06.04_Measurements'];
end
if ~exist('file_prefixOT', 'var')
    file_prefixOT = 'cont_OpticalTracking';
end
if ~exist('file_prefixEMT', 'var')
    file_prefixEMT = 'cont_EMTracking';
end
dOT = dir([file_path filesep file_prefixOT '*']);
dEM = dir([file_path filesep file_prefixEMT '*']);

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
amountErrorPointsEM = [0 0];
goodOTPts = [];
goodEMPts = [];


%pointsToTake = 100;

% take all points in the file
pointsToTake = 0; 

if ~exist('datafreq', 'var')
    % define desired polling frequency
    datafreq = 25; % 25 Hz
end
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
    fileIDOT = fopen([file_path filesep namesOT{j}],'r');
    dataArrayOT = textscan(fileIDOT, formatSpecOT, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true,  'ReturnOnError', false);
    TempPosition = [str2double(dataArrayOT{1,2}), str2double(dataArrayOT{1,3}), str2double(dataArrayOT{1,4})];
    TempOrient = [str2double(dataArrayOT{1,6}), str2double(dataArrayOT{1,7}), str2double(dataArrayOT{1,8}), str2double(dataArrayOT{1,9})];
    TimeStampOT = str2double(dataArrayOT{1,11});
    TimeStampOT = round(TimeStampOT / timeStampDivision);
    % Stores OT in the cell
    numPointsOT = size(TempPosition,1);
    if pointsToTake~=0&&numPointsOT>pointsToTake
        numPointsOT=pointsToTake;
    end
    for k = 1:numPointsOT
         if (TempPosition(k,1) < 10000 && TempPosition(k,1) > -10000  && TempPosition(k,2) < 10000 && TempPosition(k,2) > -10000  && TempPosition(k,3) < 10000 && TempPosition(k,3) > -10000)
             dataOT{k-amountErrorPointsOT,1}.position=TempPosition(k,:);
             dataOT{k-amountErrorPointsOT,1}.orientation=TempOrient(k,:);
             dataOT{k-amountErrorPointsOT,1}.TimeStamp=TimeStampOT(k);
             goodOTPts = [goodOTPts k];
         else
             amountErrorPointsOT = amountErrorPointsOT + 1;
         end
    end
    numPointsOT = size(dataOT(:,1),1)
   % clear TempPosition dataArrayOT TempOrient fileIDOT;
   
    % LOAD EM
    fileIDEM = fopen([file_path filesep namesEM{j}],'r');
    dataArrayEM = textscan(fileIDEM, formatSpecEM, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true,  'ReturnOnError', false);
    TempPosition= [str2double(dataArrayEM{1,4}), str2double(dataArrayEM{1,5}), str2double(dataArrayEM{1,6})];
    TempOrient = [str2double(dataArrayEM{1,8}), str2double(dataArrayEM{1,9}), str2double(dataArrayEM{1,10}), str2double(dataArrayEM{1,11})];
    % Split the raw data according to the 3 sensors
    TimeStampEM = str2double(dataArrayEM{1,13});
    TimeStampEM = round(TimeStampEM / timeStampDivision);
    index0 = 1; index1 = 1; index2 = 1;
    for i = 1:size(TempPosition)
        SensorIndex0based = int8(str2double(dataArrayEM{1,2}(i)));
        l=SensorIndex0based+1;
        switch SensorIndex0based;
            case 0
                TempPositionFirstSensor(index0,:) = TempPosition(i,:);
                TempOrientFirstSensor(index0,:) = TempOrient(i,:);
                TempTimeFirstSensor(index0) = TimeStampEM(i);
                if (abs(TempPositionFirstSensor(index0,1)) < 10000)
                    dataEM{index0-amountErrorPointsEM(l),l}.position=TempPositionFirstSensor(index0,:);
                    dataEM{index0-amountErrorPointsEM(l),l}.orientation=TempOrientFirstSensor(index0,:);
                    dataEM{index0-amountErrorPointsEM(l),l}.TimeStamp=TempTimeFirstSensor(index0);
                    goodEMPts = [goodEMPts k];
                else
                    amountErrorPointsEM(l) = amountErrorPointsEM(l) + 1;
                end
                index0 = index0 + 1;
            case 1
                TempPositionSecondSensor(index1,:) = TempPosition(i,:);
                TempOrientSecondSensor(index1,:) = TempOrient(i,:);
                TempTimeSecondSensor(index1) = TimeStampEM(i);
                if (abs(TempPositionSecondSensor(index1,1)) < 10000)
                    dataEM{index1-amountErrorPointsEM(l),l}.position=TempPositionSecondSensor(index1,:);
                    dataEM{index1-amountErrorPointsEM(l),l}.orientation=TempOrientSecondSensor(index1,:);
                    dataEM{index1-amountErrorPointsEM(l),l}.TimeStamp=TempTimeSecondSensor(index1);
                    goodEMPts = [goodEMPts k];
                else
                    amountErrorPointsEM(l) = amountErrorPointsEM(l) + 1;
                end
                index1 = index1 + 1;
        end
    end
       
    % Stores EM in the cell
    numPointsEMT1 = size(dataEM(:,1),1)
%     numPointsEMT2 = size(dataEM(:,2),1)
    numSensorsEM = size(dataEM,2)
    if pointsToTake~=0&&numPointsEM>pointsToTake
        numPointsEM=pointsToTake;
    end


end %for loop


end