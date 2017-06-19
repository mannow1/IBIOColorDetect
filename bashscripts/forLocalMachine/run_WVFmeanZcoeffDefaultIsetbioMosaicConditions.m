function run_WVFmeanZcoeffDefaultIsetbioMosaicConditions(computationInstance)
function run_cBanksEtAlPhotocurrentAndEyeMovementsJob()

    % 'WvfHuman', 'Geisler'
    opticsModel = 'Geisler';

    % 'originalBanks'; 'defaultIsetbio';  'fullIsetbioNoScones'; 'fullIsetbioWithScones'
    mosaicType =  'originalBanks';
    
    % 'singleExposure'; 'timeSeries5msec'
    temporalAnalysis = 'timeSeries5msec';
    
    % 'random'; 'frozen0';
    emPathType = 'frozen0'; %random'; %'random';     
    centeredEMPaths = false;
    
    % 'isomerizations', 'photocurrents'
    performanceSignal = 'isomerizations';
    
    % Use a subset of the trials. Specify [] to use all available trials
    nTrainingSamples = 1024;
    
    
    % 'mlpt', 'svm', 'svmV1FilterBank'
    performanceClassifier = 'mlpt'; %'mlpt'% 'svmV1FilterBank';
    useRBFSVMKernel = false;
    
    % Spatial pooling kernel parameters
    spatialPoolingKernelParams.type = 'V1QuadraturePair';  % Choose between 'V1CosUnit' 'V1SinUnit' 'V1QuadraturePair';
    spatialPoolingKernelParams.activationFunction = 'energy';  % Choose between 'energy' and 'fullWaveRectifier'
    spatialPoolingKernelParams.adjustForConeDensity = false;
    spatialPoolingKernelParams.temporalPCAcoeffs = Inf;  % Inf, results in no PCA, just the raw time series
    spatialPoolingKernelParams.shrinkageFactor = 1.0;  % > 1, results in expansion, < 1 results in shrinking
    
   
    freezeNoise = ~true;
    luminancesExamined =  [34]; 

    computationIntance = 1;
    
    if (computationIntance == 0)
        % All conditions in 1 MATLAB session
        ramPercentageEmployed = 1.0;  % use all the RAM
        cyclesPerDegreeExamined =  [2.5 5 10 20 40 50];
    elseif (computationIntance  == 1)
        % First half of the conditions in session 1 of 2 parallel MATLAB sessions
        ramPercentageEmployed = 0.5;  % use all of the RAM
        cyclesPerDegreeExamined =  [2.5];
    elseif (computationIntance  == 2)
        % Second half of the conditions in session 2 of 2 parallel MATLAB sessions
        ramPercentageEmployed = 0.3;  % use 1/2 the RAM
        cyclesPerDegreeExamined =  [5.0];
    elseif (computationIntance  == 3)
        % Second half of the conditions in session 2 of 2 parallel MATLAB sessions
        ramPercentageEmployed = 0.3;  % use 1/2 the RAM
        cyclesPerDegreeExamined =  [10 20 40 50];
    end
    

    % What to do ?
    computeMosaic = ~true;
    visualizeMosaic = ~true;
    computeResponses = true;
    computePhotocurrentResponseInstances = ~true;
    visualizeResponses = ~true;
    visualizeSpatialScheme = ~true;
    findPerformance = true;
    visualizePerformance = true;
    visualizeTransformedSignals = ~true;
    deleteResponseInstances = ~true;
    
    
    switch mosaicType
        case 'originalBanks'
            % 1. Original Banks et al mosaic params
            coneSpacingMicrons = 3.0;
            innerSegmentDiameter = 3.0;    % for a circular sensor
            conePacking = 'hexReg';
            LMSRatio = [0.67 0.33 0];
            mosaicRotationDegs = 30;
            
        case 'defaultIsetbio'
            % 2. Default isetbio mosaic params
            coneSpacingMicrons = 2.0;
            innerSegmentDiameter = 1.5797; % for a circular sensor; this corresponds to the 1.4 micron square pixel 
            conePacking = 'hexReg';
            LMSRatio = [0.67 0.33 0.0];
            mosaicRotationDegs = 0;
            
        case 'fullIsetbioNoScones'
            % 3. spatially-varying density isetbio mosaic params
            coneSpacingMicrons = 2.0;
            innerSegmentDiameter = 1.5797; % for a circular sensor; this corresponds to the 1.4 micron square pixel 
            conePacking = 'hex';
            LMSRatio = [0.67 0.33 0];
            mosaicRotationDegs = 0;
            
        case 'fullIsetbioWithScones'
            % 3. spatially-varying density isetbio mosaic params
            coneSpacingMicrons = 2.0;
            innerSegmentDiameter = 1.5797; % for a circular sensor; this corresponds to the 1.4 micron square pixel 
            conePacking = 'hex';
            LMSRatio = [0.60 0.30 0.10];
            mosaicRotationDegs = 0;
        otherwise
            error('Unknown mosaicType: ''%s''.', mosaicType);
    end
    
    
    switch temporalAnalysis 
        case 'singleExposure'
            % For 100 ms simulation
            responseStabilizationMilliseconds = 0;
            responseExtinctionMilliseconds = 100;
            integrationTimeMilliseconds =  100;
            lowContrast = 0.001;
            highContrast = 0.3;
            nContrastsPerDirection =  12;    
            
        case 'timeSeries5msec'
            % For 5.0 milliseconds simulation
            responseStabilizationMilliseconds = 10;
            responseExtinctionMilliseconds = 50;
            integrationTimeMilliseconds =  5.0;
            lowContrast = 0.0001;
            highContrast = 0.3;
            nContrastsPerDirection =  18;    
    
        case 'demoForFigures'
            % For 7.0 milliseconds simulatio            
            responseStabilizationMilliseconds = 50;
            responseExtinctionMilliseconds = 450;
            integrationTimeMilliseconds =  5.0;
            lowContrast = 0.75;
            highContrast = 0.75;
            nContrastsPerDirection =  1;  
            nTrainingSamples = 128;
            performanceTrialsUsed = nTrainingSamples;
            
    end
    
    if (deleteResponseInstances)
        c_BanksEtAlPhotocurrentAndEyeMovements(...
            'opticsModel', opticsModel, ...
            'cyclesPerDegree', cyclesPerDegreeExamined, ...
            'luminances', luminancesExamined, ...
            'nTrainingSamples', nTrainingSamples, ...
            'lowContrast', lowContrast, ...
            'highContrast', highContrast, ...
            'nContrastsPerDirection', nContrastsPerDirection, ...
            'ramPercentageEmployed', ramPercentageEmployed, ...
            'emPathType', emPathType, ...
            'centeredEMPaths', centeredEMPaths, ...
            'responseStabilizationMilliseconds', responseStabilizationMilliseconds, ...
            'responseExtinctionMilliseconds', responseExtinctionMilliseconds, ...
            'freezeNoise', freezeNoise, ...
            'integrationTime', integrationTimeMilliseconds/1000, ...
            'coneSpacingMicrons', coneSpacingMicrons, ...
            'innerSegmentSizeMicrons', sizeForSquareApertureFromDiameterForCircularAperture(innerSegmentDiameter), ...
            'conePacking', conePacking, ...
            'LMSRatio', LMSRatio, ...
            'mosaicRotationDegs', mosaicRotationDegs, ...
            'computeMosaic', false, ...
            'visualizeMosaic', false, ...
            'computeResponses', false, ...
            'computePhotocurrentResponseInstances', false, ...
            'visualizeResponses', false, ...
            'visualizeSpatialScheme', false, ...
            'findPerformance', false, ...
            'visualizePerformance', false, ...
            'deleteResponseInstances', true);
        return;
    end
    
    if (computeResponses) || (visualizeResponses) || (visualizeMosaic)
        c_BanksEtAlPhotocurrentAndEyeMovements(...
            'opticsModel', opticsModel, ...
            'cyclesPerDegree', cyclesPerDegreeExamined, ...
            'luminances', luminancesExamined, ...
            'nTrainingSamples', nTrainingSamples, ...
            'lowContrast', lowContrast, ...
            'highContrast', highContrast, ...
            'nContrastsPerDirection', nContrastsPerDirection, ...
            'ramPercentageEmployed', ramPercentageEmployed, ...
            'emPathType', emPathType, ...
            'centeredEMPaths', centeredEMPaths, ...
            'responseStabilizationMilliseconds', responseStabilizationMilliseconds, ...
            'responseExtinctionMilliseconds', responseExtinctionMilliseconds, ...
            'freezeNoise', freezeNoise, ...
            'integrationTime', integrationTimeMilliseconds/1000, ...
            'coneSpacingMicrons', coneSpacingMicrons, ...
            'innerSegmentSizeMicrons', sizeForSquareApertureFromDiameterForCircularAperture(innerSegmentDiameter), ...
            'conePacking', conePacking, ...
            'LMSRatio', LMSRatio, ...
            'mosaicRotationDegs', mosaicRotationDegs, ...
            'computeMosaic',computeMosaic, ...
            'visualizeMosaic', visualizeMosaic, ...
            'computeResponses', computeResponses, ...
            'computePhotocurrentResponseInstances', computePhotocurrentResponseInstances, ...
            'visualizeResponses', visualizeResponses, ...
            'visualizeSpatialScheme', visualizeSpatialScheme, ...
            'findPerformance', false, ...
            'visualizePerformance', false, ...
            'performanceSignal' , performanceSignal, ...
            'performanceClassifier', performanceClassifier ...
        );
    end
    
    
    if (findPerformance) || (visualizePerformance)
            perfData = c_BanksEtAlPhotocurrentAndEyeMovements(...
                'opticsModel', opticsModel, ...
                'cyclesPerDegree', cyclesPerDegreeExamined, ...
                'luminances', luminancesExamined, ...
                'nTrainingSamples', nTrainingSamples, ...
                'nContrastsPerDirection', nContrastsPerDirection, ...
                'lowContrast', lowContrast, ...
                'highContrast', highContrast, ...
                'ramPercentageEmployed', ramPercentageEmployed, ...
                'emPathType', emPathType, ...
                'centeredEMPaths', centeredEMPaths, ...
                'responseStabilizationMilliseconds', responseStabilizationMilliseconds, ...
                'responseExtinctionMilliseconds', responseExtinctionMilliseconds, ...
                'freezeNoise', freezeNoise, ...
                'integrationTime', integrationTimeMilliseconds/1000, ...
                'coneSpacingMicrons', coneSpacingMicrons, ...
                'innerSegmentSizeMicrons', sizeForSquareApertureFromDiameterForCircularAperture(innerSegmentDiameter), ...
                'conePacking', conePacking, ...
                'LMSRatio', LMSRatio, ...
                'mosaicRotationDegs', mosaicRotationDegs, ...
                'computeMosaic', false, ...
                'visualizeMosaic', false, ...
                'computeResponses', false, ...
                'visualizeResponses', false, ...
                'visualizeSpatialScheme', visualizeSpatialScheme, ...
                'findPerformance', findPerformance, ...
                'visualizePerformance', visualizePerformance, ...
                'visualizeTransformedSignals', visualizeTransformedSignals, ...
                'parforWorkersNumForClassification', 4, ...
                'performanceSignal' , performanceSignal, ...
                'performanceClassifier', performanceClassifier, ...
                'useRBFSVMKernel', useRBFSVMKernel, ...
                'performanceTrialsUsed', nTrainingSamples, ...
                'spatialPoolingKernelParams', spatialPoolingKernelParams ...
                );
            referenceThreshold = perfData.mlptThresholds.thresholdContrasts
    end
end
