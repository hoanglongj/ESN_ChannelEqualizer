% This file trains the network created by generateESN.m with the training
% data generated by generateData.m.

%% Data preparation
% Training data extraction
sampleOut = trainOut;

% Data splitting
washoutLength = 100;
trainingLength = 5000;

%% Noise level
noiselevel = 1e-10;

%% Parameters for RLS algorithm
% P-matrix is a diagonal auxiliary matrix with large entries of size 10^10
delta = 10^10;
P_matrix = delta * eye(internalLength + 1, internalLength + 1);

% Forgetting factor
forget_fact = 0.998;

%% Data initialization for learning
% Activation state of all units   
totalstate =  zeros(totalDim,1);                

% Activation states of internal units
internalState = totalstate(1:internalLength);           

% Output weight matrix (trainable)
outWM = initialOutWM';                           

% Collection of all activation states during training period for learning
stateCollectMat = zeros(trainingLength, internalLength + inputLength);
teachCollectMat = zeros(trainingLength, outputLength);

%% Parameter visualization
fprintf('Initialization:\n')
fprintf('Spectral radius = %g   reservoirSize = %g   TrainingLength = %g\n',...
    spectralRadius, internalLength, trainingLength);

fprintf('Start learning...\n')

%% Scanning through training data
for i = 1 : washoutLength + trainingLength 
    %% Teacher extraction
    teach = sampleOut(1,i);    
    
    %% Input update
    % Input unit initialization
    in = trainIn(1,i);
    
    % Update input into totalstate
    totalstate(internalLength+1:internalLength+inputLength) = in; 
    
    %% Internal state update
    % Update internal state
    if noiselevel == 0 ||  i > washoutLength + trainingLength
        internalState = ([intWM, inWM, ofbWM]*totalstate);  
    else
        internalState = ([intWM, inWM, ofbWM]*totalstate + ...
                noiselevel * 2.0 * (rand(internalLength,1)-0.5));
    end
    
    %% RLS algorithm for output weight update
    if i > washoutLength
        % Concatenate internal states and input state
        v = [internalState;in];
        
        % Update u and k matrices
        u_matrix = P_matrix * v;
        k = u_matrix ./ (forget_fact + v' * u_matrix); 
        
        % Update output units
        netOut = outWM' * v;
        
        % Error between teacher and computed output
        er = teach - netOut;
        
        % Output matrix update
        outWM = outWM + k * er;
        
        % Update P-matrix
        P_matrix = (1/forget_fact) * (P_matrix - k * (v' * P_matrix));
    else
        % Concatenate internal states and input state
        v = [internalState;in];
        netOut = outWM' * v;
    end
    
    totalstate = [internalState;in;netOut];    

end

fprintf('Learning completed!\n');








