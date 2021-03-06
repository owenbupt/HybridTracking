%% data read in
% do preparation
clear variables globals;
close all;

pathGeneral = fileparts(fileparts(fileparts(fileparts(which(mfilename)))));
path = [pathGeneral filesep 'measurements' filesep 'testmfrom_NDItrack'];
testrow_name_EMT = 'hybridEMT';
testrow_name_OT = 'hybridOT';

% get data for hand/eye calib
[data_EMT] = read_NDI_tracking_files(path, testrow_name_EMT);
[data_OT] = read_NDI_tracking_files(path, testrow_name_OT);

% Variables
numPts = size(data_EMT,1);
numSensors = 1;
numUnknowns = 6;
mat=cell(numPts-1,numSensors);
points = cell(numPts,numSensors);

% a is EMT
% b is OT
reset(symengine)

% Obtain matrix H(4x4) for each point
for i = 1:numPts
    for j = 1:numSensors
        points{i,j}.Ha = getMatrixH((data_EMT{i,j}.orientation(2:4))',data_EMT{i,j}.position');
        points{i,j}.Hb = getMatrixH((data_OT{i}.orientation(2:4))',data_OT{i}.position');                
    end
end

% Parameters for each movement
for i = 1:numPts-1
    for j = 1:numSensors
        
        % First we have to compute the motion!!!
        [mat{i,j}.aRotation,mat{i,j}.aTranslation] = obtainQuatMotion(points{i,j}.Ha, points{i+1,j}.Ha);
        [mat{i,j}.bRotation,mat{i,j}.bTranslation] = obtainQuatMotion(points{i,j}.Hb, points{i+1,j}.Hb);
        
        mat{i,j}.aPrime = 0.5*mat{i,j}.aTranslation.*mat{i,j}.aRotation;
        mat{i,j}.bPrime = 0.5*mat{i,j}.bTranslation.*mat{i,j}.bRotation;
        
        mat{i,j}.skew = skew(mat{i,j}.aRotation+mat{i,j}.bRotation);
        mat{i,j}.skewPrime = skew(mat{i,j}.aPrime+mat{i,j}.bPrime);
        
        % Definition of symbolic variables and assign
        syms rx ry rz tx ty tz;
        mat{i,j}.q = [0; rx; ry; rz];
        mat{i,j}.qPrime = [0; 0.5*tx*rx; 0.5*ty*ry; 0.5*tz*rz];
        clear rx ry rz tx ty tz;
        
        mat{i,j}.x = [mat{i,j}.q; mat{i,j}.qPrime];
        
        % Definition of matrix constraints and eq system
        mat{i,j}.C =    [mat{i,j}.aRotation-mat{i,j}.bRotation mat{i,j}.skew zeros(3,1) zeros(3,3);...
                         mat{i,j}.aPrime-mat{i,j}.bPrime mat{i,j}.skewPrime mat{i,j}.aRotation-mat{i,j}.bRotation mat{i,j}.skew];
        
        mat{i,j}.Cx = (mat{i,j}.C)*(mat{i,j}.x);
        mat{i,j}.constraints = [dot(conj(mat{i,j}.q),mat{i,j}.q)-1;...
                                dot(conj(mat{i,j}.q),mat{i,j}.qPrime) + dot(conj(mat{i,j}.qPrime),mat{i,j}.q)];
        mat{i,j}.equations = [mat{i,j}.Cx; mat{i,j}.constraints];
                 
    end
    
end


%% OPTIMIZER
        
fh = @(x) objectiveFunction(x, mat, numPts, numSensors);
options = optimset('TolX',1e-8, 'algorithm', 'trust-region-reflective', 'MaxIter', 10000);
%options = optimset('algorithm', 'levenberg-marquardt', 'TolFun', 1e-20);
x0 = [0; -0.85; -0.45; -10; -2; -49];
lowBnd = [-1; -1; -1; -100; -100; -100];
uppBnd = [1; 1; 1; 100; 100; 100];

% Option 1: FMINSEARCH with boundaries
% [transform_params, min_value,exitflag] = fminsearchbnd(fh,x0,lowBnd,uppBnd,options);
% Option 2: FMINSEARCH without boundaries
% [transform_params, min_value,exitflag] = fminsearch(fh,x0,options);
% Option 3: LSQNONLIN
x = lsqnonlin(fh,x0,lowBnd,uppBnd,options);



%%

% Solutions together in an array
clear qx qy qz tx ty tz;
solutions = zeros(numPts-1,numUnknowns*numSensors*2);
for i = 1:numPts-1
    final=0;
    for j = 1:numSensors
        for k = 1:numUnknowns
            solutions(i,final+k*2-1:final+k*2)=mat{i,j}.solutionNum(k,:);
        end
        final=2*(final+numUnknowns)+1;
    end
end