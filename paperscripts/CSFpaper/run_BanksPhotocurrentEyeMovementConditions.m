function varargout = run_BanksPhotocurrentEyeMovementConditions(params)
 
varargout = {};
varargout{1} = [];
varargout{2} = [];
varargout{3} = [];

    % Assign parfor workers num based on computer name
    [~, computerNetworkName] = system('uname -n');
    if (contains(computerNetworkName, 'ionean'))
        params.parforWorkersNum = 10;
    elseif (contains(computerNetworkName, 'leviathan'))
        params.parforWorkersNum = 20;
    else
        params.parforWorkersNum = 4;
    end
    fprintf('\nWill use %d workers\n', params.parforWorkersNum);

    if (params.deleteResponseInstances)
        c_BanksEtAlPhotocurrentAndEyeMovements(...
            'opticsModel', params.opticsModel, ...
            'wavefrontSpatialSamples', params.wavefrontSpatialSamples, ...              % * * * NEW
            'minimumOpticalImagefieldOfViewDegs', params.minimumOpticalImagefieldOfViewDegs, ...      % * * *  NEW
            'pupilDiamMm', params.pupilDiamMm, ...
            'blur', params.blur, ...
            'apertureBlur', params.apertureBlur, ...
            'imagePixels', params.imagePixels, ...
            'cyclesPerDegree', params.cyclesPerDegreeExamined, ...
            'luminances', params.luminancesExamined, ...
            'nTrainingSamples', params.nTrainingSamples, ...
            'lowContrast', params.lowContrast, ...
            'highContrast', params.highContrast, ...
            'nContrastsPerDirection', params.nContrastsPerDirection, ...
            'frameRate', params.frameRate, ...
            'ramPercentageEmployed', params.ramPercentageEmployed, ...
            'emPathType', params.emPathType, ...
            'centeredEMPaths', params.centeredEMPaths, ...
            'responseStabilizationMilliseconds', params.responseStabilizationMilliseconds, ...
            'responseExtinctionMilliseconds', params.responseExtinctionMilliseconds, ...
            'freezeNoise', params.freezeNoise, ...
            'integrationTime', params.integrationTimeMilliseconds/1000, ...
            'coneSpacingMicrons', params.coneSpacingMicrons, ...
            'innerSegmentSizeMicrons', params.innerSegmentDiameter, ...
            'conePacking', params.conePacking, ...
            'LMSRatio', params.LMSRatio, ...
            'mosaicRotationDegs', params.mosaicRotationDegs, ...
            'sConeMinDistanceFactor', params.sConeMinDistanceFactor, ...
            'sConeFreeRadiusMicrons', params.sConeFreeRadiusMicrons, ...
            'latticeAdjustmentPositionalToleranceF', params.latticeAdjustmentPositionalToleranceF, ...
            'latticeAdjustmentDelaunayToleranceF', params.latticeAdjustmentDelaunayToleranceF, ...
            'maxGridAdjustmentIterations', params.maxGridAdjustmentIterations, ...   % * * * NEW 
            'marginF', params.marginF, ...
            'resamplingFactor', params.resamplingFactor, ...                            % * * * NEW 
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
    
    if (params.computeResponses) || (params.visualizeMosaicWithFirstEMpath) || (params.visualizeResponses) || (params.visualizeMosaic) || (params.computeMosaic)

        [~, ~,~,~, theMosaic] = c_BanksEtAlPhotocurrentAndEyeMovements(...
            'opticsModel', params.opticsModel, ...
            'wavefrontSpatialSamples', params.wavefrontSpatialSamples, ...              % * * * NEW
            'minimumOpticalImagefieldOfViewDegs', params.minimumOpticalImagefieldOfViewDegs, ...      % * * *  NEW
            'pupilDiamMm', params.pupilDiamMm, ...
            'blur', params.blur, ...
            'apertureBlur', params.apertureBlur, ...
            'imagePixels', params.imagePixels, ...
            'cyclesPerDegree', params.cyclesPerDegreeExamined, ...
            'luminances', params.luminancesExamined, ...
            'nTrainingSamples', params.nTrainingSamples, ...
            'lowContrast', params.lowContrast, ...
            'highContrast', params.highContrast, ...
            'nContrastsPerDirection', params.nContrastsPerDirection, ...
            'frameRate', params.frameRate, ...
            'ramPercentageEmployed', params.ramPercentageEmployed, ...
            'parforWorkersNum', params.parforWorkersNum, ...
            'emPathType', params.emPathType, ...
            'centeredEMPaths', params.centeredEMPaths, ...
            'responseStabilizationMilliseconds', params.responseStabilizationMilliseconds, ...
            'responseExtinctionMilliseconds', params.responseExtinctionMilliseconds, ...
            'freezeNoise', params.freezeNoise, ...
            'integrationTime', params.integrationTimeMilliseconds/1000, ...
            'coneSpacingMicrons', params.coneSpacingMicrons, ...
            'innerSegmentSizeMicrons', params.innerSegmentDiameter, ...
            'conePacking', params.conePacking, ...
            'LMSRatio', params.LMSRatio, ...
            'mosaicRotationDegs', params.mosaicRotationDegs, ...
            'sConeMinDistanceFactor', params.sConeMinDistanceFactor, ...
            'sConeFreeRadiusMicrons', params.sConeFreeRadiusMicrons, ...
            'latticeAdjustmentPositionalToleranceF', params.latticeAdjustmentPositionalToleranceF, ...
            'latticeAdjustmentDelaunayToleranceF', params.latticeAdjustmentDelaunayToleranceF, ...
            'maxGridAdjustmentIterations', params.maxGridAdjustmentIterations, ...   % * * * NEW 
            'marginF', params.marginF, ...
            'resamplingFactor', params.resamplingFactor, ...                            % * * * NEW 
            'computeMosaic', params.computeMosaic, ...
            'visualizeMosaic', params.visualizeMosaic, ...
            'computeResponses', params.computeResponses, ...
            'computePhotocurrentResponseInstances', params.computePhotocurrentResponseInstances, ...
            'visualizeOptics', params.visualizeOptics, ...
            'visualizeOIsequence', params.visualizeOIsequence, ...
            'visualizeResponses', params.visualizeResponses, ...
            'visualizeMosaicWithFirstEMpath', params.visualizeMosaicWithFirstEMpath, ...
            'visualizeSpatialScheme', params.visualizeSpatialScheme, ...
            'findPerformance', false, ...
            'visualizePerformance', false, ...
            'performanceSignal' , params.performanceSignal, ...
            'performanceClassifier', params.performanceClassifier, ...
            'spatialPoolingKernelParams', params.spatialPoolingKernelParams ...
        );
        varargout{1} = theMosaic;
    end
    
    if (params.findPerformance) || (params.visualizePerformance)
            [perfData, ~, ~, ~, theMosaic, thePsychometricFunctions, theFigData] = c_BanksEtAlPhotocurrentAndEyeMovements(...
                'opticsModel', params.opticsModel, ...
                'wavefrontSpatialSamples', params.wavefrontSpatialSamples, ...              % * * * NEW
                'minimumOpticalImagefieldOfViewDegs', params.minimumOpticalImagefieldOfViewDegs, ...      % * * *  NEW
                'pupilDiamMm', params.pupilDiamMm, ...
                'blur', params.blur, ...
                'apertureBlur', params.apertureBlur, ...
                'imagePixels', params.imagePixels, ...
                'cyclesPerDegree', params.cyclesPerDegreeExamined, ...
                'luminances', params.luminancesExamined, ...
                'nTrainingSamples', params.nTrainingSamples, ... 
                'nContrastsPerDirection', params.nContrastsPerDirection, ...
                'frameRate', params.frameRate, ...
                'lowContrast', params.lowContrast, ...
                'highContrast', params.highContrast, ...
                'ramPercentageEmployed', params.ramPercentageEmployed, ...
                'emPathType', params.emPathType, ...
                'centeredEMPaths', params.centeredEMPaths, ...
                'responseStabilizationMilliseconds', params.responseStabilizationMilliseconds, ...
                'responseExtinctionMilliseconds', params.responseExtinctionMilliseconds, ...
                'freezeNoise', params.freezeNoise, ...
                'integrationTime', params.integrationTimeMilliseconds/1000, ...
                'coneSpacingMicrons', params.coneSpacingMicrons, ...
                'innerSegmentSizeMicrons', params.innerSegmentDiameter, ...
                'conePacking', params.conePacking, ...
                'LMSRatio', params.LMSRatio, ...
                'mosaicRotationDegs', params.mosaicRotationDegs, ...
                'sConeMinDistanceFactor', params.sConeMinDistanceFactor, ...
                'sConeFreeRadiusMicrons', params.sConeFreeRadiusMicrons, ...
                'latticeAdjustmentPositionalToleranceF', params.latticeAdjustmentPositionalToleranceF, ...
                'latticeAdjustmentDelaunayToleranceF', params.latticeAdjustmentDelaunayToleranceF, ...
                'maxGridAdjustmentIterations', params.maxGridAdjustmentIterations, ...   % * * * NEW 
                'marginF', params.marginF, ...
                'resamplingFactor', params.resamplingFactor, ...                            % * * * NEW 
                'computeMosaic', false, ...
                'visualizeMosaic', params.visualizeMosaic, ...
                'computeResponses', false, ...
                'visualizeResponses', false, ...
                'visualizeSpatialScheme', params.visualizeSpatialScheme, ...
                'findPerformance', params.findPerformance, ...
                'visualizePerformance', params.visualizePerformance, ...
                'visualizeKernelTransformedSignals', params.visualizeKernelTransformedSignals, ...
                'performanceSignal' , params.performanceSignal, ...
                'performanceClassifier', params.performanceClassifier, ...
                'performanceTrialsUsed', params.nTrainingSamples, ...
                'spatialPoolingKernelParams', params.spatialPoolingKernelParams ...
                );
           varargout{1} = theMosaic;
           varargout{2} = thePsychometricFunctions;
           varargout{3} = theFigData;
    end
end

