function run_c_DavilaGeislerReplicateEyeMovementsJob
    % What to do ?
    computeMosaic = ~true;
    visualizeMosaic = ~true;
    computeResponses = ~true;
    visualizeResponses = ~true;
    visualizeSpatialScheme = true;
    findPerformance = true;
   
    visualizePerformance = true;
    visualizeTransformedSignals = ~true;
    
    nTrainingSamples = 1024;
    spotAreaMinutes = logspace(-0.1, 2.5, 10);
    spotAreaMinutes = spotAreaMinutes(1:end);
    
    spotDiametersMinutes = fliplr(spotDiameterFromArea(spotAreaMinutes));

    %spotDiametersMicrons = spotDiametersMinutes/60*300
    
    nContrastsPerDirection = 18;
    highContrast = 0.3;
    lowContrast = 0.00003;
    backgroundSizeDegs = 0.4;  % 0.1, 0.15, 0.3 works
    
    blur = false;           % NO OPTICS
    emPathType = 'frozen0'; % 'frozen0'; %random'; %'random';
    conePacking = 'hex';
    LMSRatio = [0.62 0.31 0.07];
    coneSpacingMicrons = 2.0;
    innerSegmentSizeMicrons = 1.5797; % for a circular sensor; this corresponds to the 1.4 micron square pixel 
    
    responseStabilizationMilliseconds = 20;
    responseExtinctionMilliseconds = 60;

    thresholdSignal = 'isomerizations';
    thresholdMethod = 'mlpt'; % 'svmGaussianRF'; %'svm'; %'mlpt'%
    useRBFSVMKernel = false;
    
    % Spatial pooling kernel parameters
    spatialPoolingKernelParams.type = 'GaussianRF';
    spatialPoolingKernelParams.activationFunction = 'linear';  % Choose between 'energy' and 'fullWaveRectifier'
    spatialPoolingKernelParams.adjustForConeDensity = false;
    spatialPoolingKernelParams.temporalPCAcoeffs = Inf;  % Inf, results in no PCA, just the raw time series
    spatialPoolingKernelParams.shrinkageFactor = -2.0/60;  % > 1, results in expansion, > 0 < 1 results in shrinking, < 0 means the actual sigma in degs
    
    if (computeResponses) || (visualizeResponses) || (visualizeSpatialScheme) || (visualizeMosaic)
        c_DavilaGeislerReplicateEyeMovements(...
            'nTrainingSamples', nTrainingSamples, ...
            'backgroundSizeDegs', backgroundSizeDegs, ...
            'spotDiametersMinutes', spotDiametersMinutes, ...
            'imagePixels', 1000, ...
            'blur', blur, ...
            'highContrast', highContrast, ...
            'lowContrast', lowContrast, ...
            'nContrastsPerDirection', nContrastsPerDirection, ...
            'conePacking', conePacking, ...
            'coneSpacingMicrons', coneSpacingMicrons, ...
            'innerSegmentSizeMicrons', innerSegmentSizeMicrons, ...
            'LMSRatio', LMSRatio, ...
            'computeMosaic', computeMosaic, ...
            'computeResponses', computeResponses, ...
            'emPathType', emPathType, ...
            'responseStabilizationMilliseconds', responseStabilizationMilliseconds, ...
            'responseExtinctionMilliseconds', responseExtinctionMilliseconds, ...
            'visualizeMosaic', visualizeMosaic, ...
            'visualizeResponses', visualizeResponses, ...
            'visualizeSpatialScheme', visualizeSpatialScheme, ...
            'visualizeTransformedSignals', visualizeTransformedSignals, ...
            'findPerformance', false, ...
            'fitPsychometric', false, ...
            'visualizePerformance', false, ...
            'thresholdCriterionFraction', 0.701, ...
            'thresholdSignal' , thresholdSignal, ...
            'thresholdMethod', thresholdMethod ...
        );
    end
    
    
    if (findPerformance) || (visualizePerformance)
        c_DavilaGeislerReplicateEyeMovements(...
            'nTrainingSamples', nTrainingSamples, ...
            'backgroundSizeDegs', backgroundSizeDegs, ...
            'spotDiametersMinutes', spotDiametersMinutes, ...
            'imagePixels', 1000, ...
            'blur', blur, ...
            'highContrast', highContrast, ...
            'lowContrast', lowContrast, ...
            'nContrastsPerDirection', nContrastsPerDirection, ...
            'conePacking', conePacking, ...
            'coneSpacingMicrons', coneSpacingMicrons, ...
            'innerSegmentSizeMicrons', innerSegmentSizeMicrons, ...
            'LMSRatio', LMSRatio, ...
            'computeMosaic', false, ...
            'computeResponses', false, ...
            'emPathType', emPathType, ...
            'responseStabilizationMilliseconds', responseStabilizationMilliseconds, ...
            'responseExtinctionMilliseconds', responseExtinctionMilliseconds, ...
            'visualizeMosaic', false, ...
            'visualizeResponses', visualizeResponses, ...
            'visualizeSpatialScheme', visualizeSpatialScheme, ...
            'visualizeTransformedSignals', visualizeTransformedSignals, ...
            'findPerformance', findPerformance, ...
            'fitPsychometric', true, ...
            'visualizePerformance', visualizePerformance, ...
            'thresholdSignal' , thresholdSignal, ...
            'thresholdMethod', thresholdMethod, ...
            'useRBFSVMKernel', useRBFSVMKernel, ...
            'spatialPoolingKernelParams', spatialPoolingKernelParams ...
        );
    end
end

function diameter = spotDiameterFromArea(area)
    diameter = 2.0*sqrt(area/pi);
end

