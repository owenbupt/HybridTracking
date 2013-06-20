function [frame, invframe] = common_EMT_frame_from_cell(H_EMT_to_EMCS_cell, verbosity)

if ~exist('verbosity', 'var')
    verbosity = 'vDebug';
end

numPts = size(H_EMT_to_EMCS_cell{1},3);
numSen = size(H_EMT_to_EMCS_cell,2);

if numSen > 1
    % plot position data
    if strcmp(verbosity,'vDebug')
    figurehandle = Plot_points(H_EMT_to_EMCS_cell(2:end),[], 2);
    Plot_points(H_EMT_to_EMCS_cell(1), figurehandle, 1); %EMT1 is blue
    title('Interpolated position of EM sensors')
    end

    % get average EMT H_differences
    H_diff=cell(1,numSen-1);

    for j=2:numSen
        errorPoints = 0;
        for i=1:numPts
            %calculate position of sensors 2, 3, etc relative to sensor 1
            %check translations in these matrices.. if any of both is
            %bad: don't add to H_diff
            %check if a point exists for the wished timestamp
%             H_EMT_to_EMCS_cell{j}(1,4,i)
%             H_EMT_to_EMCS_cell{j}(2,4,i)
%             H_EMT_to_EMCS_cell{j}(3,4,i)
            if ( ( abs(H_EMT_to_EMCS_cell{1}(1,4,i)) > 10000 ) || ( abs(H_EMT_to_EMCS_cell{j}(1,4,i)) > 10000 ) )
                % point invalid
                errorPoints = errorPoints+1;
            else    
                H_diff{j-1}(:,:,i-errorPoints) = inv(H_EMT_to_EMCS_cell{1}(:,:,i))*H_EMT_to_EMCS_cell{j}(:,:,i);
            end
        end
        H_diff{j-1} = mean_transformation(H_diff{j-1});
    end
% % save('H_EMTx_to_EMT1.mat', 'H_diff')
%     % project every EMT 2 etc to EMT 1, build average
%     data_EM_common = cell(1,1);
%     frameWithoutError = zeros(4,4,1);
%     errorPoints = 0;
%     H_new = cell(1,numSen-1);
%     if strcmp(verbosity,'vDebug')
%     numberOfSensors_fig = figure;
%     title('Number of EM sensors used to compute common frame')
%     end
%     goodSens_array = zeros(1,numPts);
%     for i=1:numPts
%         collectframe = zeros(4);
%         goodSens = 0;
%         if ( abs(H_EMT_to_EMCS_cell{1}(1,4,i)) > 10000 )
%             % point invalid
%         else            
%             collectframe(:,:,1) = H_EMT_to_EMCS_cell{1}(:,:,i);
%             goodSens = goodSens + 1;
%         end
%         
%         for j=2:numSen
%             if ( abs(H_EMT_to_EMCS_cell{j}(1,4,i)) > 10000 )
%                 % point invalid
%             else            
%                 H_new{j-1} = H_EMT_to_EMCS_cell{j}(:,:,i)*inv(H_diff{j-1});
%                 collectframe(:,:,j) = H_new{j-1};
%                 goodSens = goodSens + 1;
%             end
%         end
%         goodSens_array(i)=goodSens;
%         % new and nice mean value creation
%         data_EM_common{i,1}.TimeStamp = startTime + i* stepsize;
%         if (goodSens == 0) %in case no sensor is good: no new entry in frameWithoutError,
%                            %same entry again in data_EM_common..?
%             errorPoints = errorPoints + 1;
%             data_EM_common{i,1}.position = data_EM_common{i-1,1}.position;
%             data_EM_common{i,1}.orientation(1:4) = data_EM_common{i-1}.orientation;
%             data_EM_common{i,1}.valid = 0;
%         else
%             frameWithoutError(:,:,i-errorPoints) = mean_transformation(collectframe);
%             data_EM_common{i,1}.position(1:3) = frameWithoutError(1:3,4,i-errorPoints);
%             R = frameWithoutError(1:3,1:3,i-errorPoints);
%             data_EM_common{i,1}.orientation(1:4) = rot2quat_q41(R);
%             data_EM_common{i,1}.valid = 1;
%         end
%     end
%     %plot number of used sensors per position
%     if strcmp(verbosity,'vDebug')
%     hold on
%     plot(goodSens_array, 'x');
%     hold off
%     end    
%     H_commonEMT_to_EMCS = frameWithoutError;
%     H_EMCS_to_commonEMT = zeros(4,4,size(H_commonEMT_to_EMCS,3));
%     for i=1:size(H_commonEMT_to_EMCS,3)
%         H_EMCS_to_commonEMT(:,:,i) = inv(H_commonEMT_to_EMCS(:,:,i));
%     end
%     
%     % plot position data of synthesized position
%     if strcmp(verbosity,'vDebug')
%     wrappercell{1}=H_commonEMT_to_EMCS;
%     Hmatrix = trackingdata_to_matrices(data_EMT,'CppCodeQuat');
%     hold on
%     SensorPosition_fig = Plot_points(wrappercell, [], 1);%synth. data is blue
%     Plot_points(Hmatrix,SensorPosition_fig,2);
%     hold off
%     title('Original position of EM sensors and computed common frame (blue)')
%     end
%     
% else
%     H_commonEMT_to_EMCS = H_EMT_to_EMCS_cell{1};
%     numPts = size(data_EMT,1);
%     H_EMCS_to_commonEMT = zeros(4,4,numPts);
%     for i=1:numPts
%         H_EMCS_to_commonEMT(:,:,i) = inv(H_commonEMT_to_EMCS(:,:,i));
%     end
% end

if numSen > 1
    % plot position data
    figurehandle = Plot_points(H_EMT_to_EMCS_cell(2:end),[], 2);
    Plot_points(H_EMT_to_EMCS_cell(1), figurehandle, 1); %EMT1 is blue

    % get average EMT H_differences
    H_diff=cell(1,numSen-1);

    for j=2:numSen
        errorPoints = 0;
        for i=1:numPts
            %calculate position of sensors 2, 3, etc relative to sensor 1
            %check translations in these matrices.. if any of both is
            %bad: don't add to H_diff
            if (abs(H_EMT_to_EMCS_cell{1}(1,4,i)) > 10000 || abs(H_EMT_to_EMCS_cell{j}(1,4,i)) > 10000)
                errorPoints = errorPoints+1;
            else
                % H_diff points from the sensor 2, 3, ... to sensor 1
                H_diff{j-1}(:,:,i-errorPoints) = inv(H_EMT_to_EMCS_cell{1}(:,:,i))*H_EMT_to_EMCS_cell{j}(:,:,i);
            end
        end
        H_diff{j-1}(:,:,1) = mean(H_diff{j-1}(:,:,:),3); 
        H_diff{j-1} = H_diff{j-1}(:,:,1); %H_diff contains only one transformation matrix
        for col = 1:3
            % normalize rotation matrix vectors
            H_diff{j-1}(1:3,col)=H_diff{j-1}(1:3,col)/norm(H_diff{j-1}(1:3,col));
        end
    end

    % project every EMT 2 etc to EMT 1, build average
    frame = zeros(4,4,numPts);
    frameWithoutError = zeros(4,4,1);
    H_new = cell(1,numSen-1);
    errorPoints = 0;
    for i=1:numPts
        goodSens = 0;
        if ( abs(H_EMT_to_EMCS_cell{1}(1,4,i)) > 10000 )
            % do nothing
        else            
            frame(:,:,i) = H_EMT_to_EMCS_cell{1}(:,:,i);
            goodSens = goodSens + 1;
        end
        for j=2:numSen
            if ( abs(H_EMT_to_EMCS_cell{j}(1,4,i)) > 10000 )
                % do nothing
            else
                % from sensor 1 to sensor 2, 3, ... to origin, so basically
                % from sensor 1 to origin. can be added to EMT to EMCS.
                H_new{j-1} = H_EMT_to_EMCS_cell{j}(:,:,i)*inv(H_diff{j-1});
                frame(:,:,i) = frame(:,:,i) + H_new{j-1};
                goodSens = goodSens + 1;
            end
        end
        % very ugly mean value creation        
        if (goodSens == 0) %in case no sensor is good: no new entry in frameWithoutError 
            errorPoints = errorPoints + 1;
        else
            frameWithoutError(:,:,i-errorPoints) = frame(:,:,i)/goodSens; %numSen;
            for col = 1:3
                % normalize rotation matrix vectors
                frameWithoutError(1:3,col,i-errorPoints)=frameWithoutError(1:3,col,i-errorPoints)/norm(frameWithoutError(1:3,col,i-errorPoints));
            end
        end
    end
    frame = frameWithoutError;
    wrappercell{1}=frame;

    % plot position data of synthesized position
    Plot_points(wrappercell, figurehandle, 5);
else
    frame = H_EMT_to_EMCS_cell{1};
end
invframe = zeros(4,4,size(frame,3));
for i=1:size(frame,3)
    invframe(:,:,i) = inv(frame(:,:,i));
end