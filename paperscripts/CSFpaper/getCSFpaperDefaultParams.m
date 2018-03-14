function params = getCSFpaperDefaultParams(mosaicName,  computationInstance)

    % Mosaic params
    mosaicParams = getParamsForMosaicWithLabel(mosaicName);
    
    fNames = fieldnames(mosaicParams);
    for k = 1:numel(fNames)
        params.(fNames{k}) = mosaicParams.(fNames{k});
    end
    
    % Integration time
    params.integrationTimeMilliseconds =  5.0;
    
    % fixational eye movements type: 'random'; 'randomNoSaccades' 'frozen0';
    params.emPathType = 'frozen0';  
    params.centeredEMPaths = false;
    
    % Stimulus luminance
    params.luminancesExamined =  [34];
    
    % Stimulus size
    params.imagePixels = 512;           % stimuli will be 512x512 pixels
    
    % Conrast axis sampling
    params.lowContrast = 0.00001*3;
    params.highContrast =  1.0;
    params.nContrastsPerDirection =  20;
    
    % Optics params
    params.opticsModel = 'ThibosDefaultSubject3MMPupil';
    params.blur = true;                 % employ optics
    params.apertureBlur = true;         % employ cone aperture blur
    params.wavefrontSpatialSamples = 261*2+1;           % This gives us an OTF sampling of 1.003 c/deg
    params.minimumOpticalImagefieldOfViewDegs = 1.0;    % optical image will be at least 1 deg
    params.pupilDiamMm = 3.0;                           % 3 is more appropriate for a 100 cd/m2 mean scene luminance
    
    
    % Trials to generate
    params.nTrainingSamples = 1024;
    
    % Freeze noise for repeatable results
    params.freezeNoise = true;
    
    % Use all trials in the classifier (Specify [] to use all available trials)
    params.performanceTrialsUsed = params.nTrainingSamples;
    
    %'mlpt', 'svm' or 'svmV1FilterBank';
    params.performanceClassifier = 'mlpt';
    
    % 'isomerizations', 'photocurrents'
    params.performanceSignal = 'isomerizations';
    
    % SVM-related
    params.useRBFSVMKernel = false;
    % Spatial pooling kernel parameters (V1-quadrature filter)
    params.spatialPoolingKernelParams.type = 'V1QuadraturePair';  % Choose between 'V1CosUnit' 'V1SinUnit' 'V1QuadraturePair';
    params.spatialPoolingKernelParams.activationFunction = 'energy';  % Choose between 'energy' and 'fullWaveRectifier'
    params.spatialPoolingKernelParams.adjustForConeDensity = false;
    params.spatialPoolingKernelParams.temporalPCAcoeffs = Inf;  % Inf, results in no PCA, just the raw time series
    params.spatialPoolingKernelParams.shrinkageFactor = 1.0;  % > 1, results in expansion, < 1 results in shrinking 
    
    % response duration params
    params.responseStabilizationMilliseconds = 40;
    params.responseExtinctionMilliseconds = 40;
    
    % Split computations and specify RAM memory
    if (computationInstance == 0)
        % All mosaic sizes in 1 MATLAB session
        params.ramPercentageEmployed = 1.2; 
        params.cyclesPerDegreeExamined =  [2 4 8 16 32 50 60]; 
    elseif (computationInstance  == 1)
        % Largest mosaic
        params.ramPercentageEmployed = 1.2; 
        params.cyclesPerDegreeExamined =  [2];
    elseif (computationInstance  == 2)
        % Second largest mosaic
        params.ramPercentageEmployed = 1.2;  
        params.cyclesPerDegreeExamined =  [4];
    elseif (computationInstance  == 3)
        % All other sizes
        params.ramPercentageEmployed = 1.2;  
        params.cyclesPerDegreeExamined =  [8 16 32 50 60];
    else
        error('computational instance must be 0, 1, 2, or 3');
    end

end
