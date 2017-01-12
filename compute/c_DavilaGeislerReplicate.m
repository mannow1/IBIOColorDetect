function [validationData, extraData] = c_BanksEtAlReplicate(varargin)
% [validationData, extraData] = c_BanksEtAlReplicate(varargin)
%
% Compute thresholds to replicate spatial summation calculations of Davila
% and Geisler, more or less.
%
% This looks at thresholds as a function of spot size.  Our stimuli are
% monochromatic rather than monitor based, but to first order that should
% not make much difference
%
% Key/value pairs
%   'useScratchTopLevelDirName'- true/false (default false). 
%      When true, the top level output directory is [scratch]. 
%      When false, it is the name of this script.
%   'nTrainingSamples' - value (default 500).  Number of training samples to cycle through.
%   'spotDiametersMinutes' - vector (default [0.5 1 5 10 20 40]). Diameters of spots to be investigated.
%   'backgroundSizeDegs' - value (default 2.1). Size of square background
%   'wavelength' - value (default 550). Wavelength to use in calculations
%   'luminances' - vector (default [3.4 34 340]).  Luminances in cd/m2 to be investigated.
%   'pupilDiamMm' - value (default 3).  Pupil diameter in mm.
%   'blur' - true/false (default true). Incorporate lens blur.
%   'innerSegmentSizeMicrons' - Diameter of the cone light-collecting area, in microns 
%       Default: sizeForSquareApertureFromDiameterForCircularAperture(3.0), where 3 microns = 6 min arc for 300 mirons/degree in the human retina.
%   'apertureBlur' - Blur by cone aperture? true/false (default false).
%   'coneSpacingMicrons' - Cone spacing in microns (3).
%   'mosaicRotationDegs' - Rotation of hex or hexReg mosaic in degrees (default 0).
%   'coneDarkNoiseRate' - Vector of LMS dark (thermal) isomerization rate iso/sec (default [0,0,0]).
%   'LMSRatio' - Ratio of LMS cones in mosaic.  Should sum to 1 (default [0.67 0.33 0]).
%   'conePacking'   - how cones are packed spatially. 
%       Choose from : 'rect', for a rectangular mosaic
%                     'hex', for a hex mosaic with an eccentricity-varying cone spacing
%                     'hexReg' for a hex mosaic witha regular cone spacing
%   'imagePixels' - value (default 400).  Size of image pixel array
%   'wavelengths' - vector (default [380 4 780).  Start, delta, end wavelength sampling.
%   'nContrastsPerDirection' - value (default 20). Number of contrasts.
%   'lowContrast' - value (default 0.0001). Low contrast.
%   'highContrast' - value (default 0.1). High contrast.
%   'contrastScale' - 'log'/'linear' (default 'log'). Contrast scale.
%   'computeResponses' - true/false (default true).  Compute responses.
%   'findPerformance' - true/false (default true).  Find performance.
%   'fitPsychometric' - true/false (default true).  Fit psychometric functions.
%   'thresholdCriterionFraction' value (default 0.75). Criterion corrrect for threshold.
%   'generatePlots' - true/false (default true).  No plots are generated unless this is true.
%   'visualizeResponses' - true/false (default false).  Do the fancy response visualization when generating responses.
%   'visualizedResponseNormalization' - string (default 'submosaicBasedZscore'). How to normalize visualized responses
%        Available options: 'submosaicBasedZscore', 'LMSabsoluteResponseBased', 'LMabsoluteResponseBased', 'MabsoluteResponseBased'
%   'plotPsychometric' - true/false (default true).  Plot psychometric functions.
%   'plotSpatialSummation' - true/false (default true).  Plot results.
%   'freezeNoise' - true/false (default true). Freeze noise so calculations reproduce.
%   'useTrialBlocks' - true/false (default true).  Break response
%        computations down into blocks?  If this is set to -1, then
%        nTrialBlocks is passed down the chain as -1, which causes the
%        underlying routines to try to be smart.  Otherwise if this is 1,
%        the nTrialsPerBlock parameter is used.
%   'nTrialsPerBlock' - value (default 50).  Target number of trials per block.

%% Parse input
p = inputParser;
p.addParameter('useScratchTopLevelDirName', false, @islogical);
p.addParameter('nTrainingSamples',500,@isnumeric);
p.addParameter('spotDiametersMinutes',[0.5 0.75 1 1.5 2 2.5 5 10 20 40],@isnumeric);
p.addParameter('backgroundSizeDegs',[2.1],@isnumeric);
p.addParameter('wavelength',550,@isnumeric);
p.addParameter('luminances',[3.4 34 340],@isnumeric);
p.addParameter('pupilDiamMm',3,@isnumeric);
p.addParameter('blur',true,@islogical);
p.addParameter('innerSegmentSizeMicrons',sizeForSquareApertureFromDiameterForCircularAperture(3.0), @isnumeric);   % 3 microns = 0.6 min arc for 300 microns/deg in human retina
p.addParameter('apertureBlur', false, @islogical);
p.addParameter('coneSpacingMicrons', 3.0, @isnumeric);
p.addParameter('mosaicRotationDegs', 0, @isnumeric);
p.addParameter('coneDarkNoiseRate',[0 0 0], @isnumeric);
p.addParameter('LMSRatio',[0.67 0.33 0],@isnumeric);
p.addParameter('conePacking', 'hexReg');                 
p.addParameter('imagePixels',400,@isnumeric);
p.addParameter('wavelengths',[380 4 780],@isnumeric);
p.addParameter('nContrastsPerDirection',20,@isnumeric);
p.addParameter('lowContrast',0.0001,@isnumeric);
p.addParameter('highContrast',0.1,@isnumeric);
p.addParameter('contrastScale','log',@ischar);
p.addParameter('computeResponses',true,@islogical);
p.addParameter('findPerformance',true,@islogical);
p.addParameter('fitPsychometric',true,@islogical);
p.addParameter('thresholdCriterionFraction',0.75,@isnumeric);
p.addParameter('generatePlots',true,@islogical);
p.addParameter('visualizeResponses',false,@islogical);
p.addParameter('visualizedResponseNormalization', 'submosaicBasedZscore', @ischar);
p.addParameter('plotPsychometric',true,@islogical);
p.addParameter('plotSpatialSummation',true,@islogical);
p.addParameter('freezeNoise',true,@islogical);
p.addParameter('useTrialBlocks',true,@islogical);
p.addParameter('nTrialsPerBlock',50,@isnumeric);
p.parse(varargin{:});

%% Get the parameters we need
%
% Start with default
rParams = responseParamsGenerate('spatialType','spot','backgroundType','AO','modulationType','AO');

%% Set the  topLevelDir name
if (~p.Results.useScratchTopLevelDirName)
    rParams.topLevelDirParams.name = mfilename;
end

%% Loop over spatial frequency
for ll = 1:length(p.Results.luminances)
    for cc = 1:length(p.Results.cyclesPerDegree)
        
        % Get stimulus parameters correct
        %
        %
        % Spatial 
        rParams.spatialParams.spotSizeDegs = p.Results.spotDiametersMinutes(dd)/60;
        rParams.spatialParams.backgroundSizeDegs = p.Results.backgroundSizeDegs;
        spatialParams.fieldOfViewDegs = 1.1*p.Results.backgroundSizeDegs;
        spatialParams.row = p.Results.imagePixels;
        spatialParams.col = p.Results.imagePixels;
        spatialParams.viewingDistance = 7.16;
        
        % Set wavelength sampling
        % WORKING HERE!!!!
        rParams.colorModulationParams.startWl = p.Results.wavelengths(1);
        rParams.colorModulationParams.deltaWl = p.Results.wavelengths(2);
        rParams.colorModulationParams.endWl = p.Results.wavelengths(3);
        
        % Optical image parameters
        %
        % The used a 3 mm artificial pupil
        rParams.oiParams = modifyStructParams(rParams.oiParams, ...
        	'blur', p.Results.blur, ...
            'pupilDiamMm', p.Results.pupilDiamMm ...    
        );
              
        % Set background parameters
        rParams.backgroundParams.backgroundWavelengthsNm = [p.Results.wavelength];
 
        % Scale radiance to produce desired background levels
        deltaWl = 10;
        S = [p.Results.wavelength deltaWl 2];
        wls = SToWls(S);
        load T_xyz1931
        T_xyz = SplineCmf(S_xyz1931,683*T_xyz1931,S);
        radiancePerUW = AOMonochromaticCornealPowerToRadiance(wls,rParams.backgroundParams.backgroundWavelengthsNm,1,rParams.oiParams.pupilDiamMm,rParams.spatialParams.backgroundSizeDegs^2);
        xyzPerUW = T_xyz*radiancePerUW;
        desiredLumCdM2 = p.Results.luminances(ll);
        rParams.backgroundParams.backgroundCornealPowerUW = desiredLumCdM2/xyzPerUW(2);
        
        % Scale spot parameters into what we think a reasonable range is.
        % In Davila & Geisler, they give thresholds in what they call
        % threshold energy, which is spotLuminance*durationSecs*areaMinutes2.
        %
        % Just to get things into a reasonable scale, we'll find a
        % luminance corresponding to a threshold energy of 10 for our
        % smallest spot.
        maxThresholdEnergy = 10;
        minSpotAreaMin2 = pi*(min(p.Results.spotDiametersMinutes)/2)^2;
        maxSpotLuminanceCdM2 = maxThresholdEnergy/((p.Results.durationMs/1000)*minSpotAreaMin2);
        rParams.colorModulationParams.startWl = p.Results.wavelength;
        rParams.colorModulationParams.endWl = p.Results.wavelength+deltaWl;
        rParams.colorModulationParams.deltaWl = deltaWl;
        rParams.colorModulationParams.spotWavelengthNm = p.Results.wavelength;
        rParams.colorModulationParams.spotCornealPowerUW = maxSpotLuminanceCdM2/xyzPerUW(2);
        rParams.colorModulationParams.contrast = 1;
        % Their stimulus intervals were 100 msec each.
        %
        % Equate stimulusSamplingIntervalInSeconds to stimulusDurationInSeconds to generate 1 time point only.
        % Their main calculation was without eye movements
        stimulusDurationInSeconds = 100/1000;
        rParams.temporalParams = modifyStructParams(rParams.temporalParams, ...
            'stimulusDurationInSeconds', stimulusDurationInSeconds, ...
            'stimulusSamplingIntervalInSeconds',  stimulusDurationInSeconds, ... 
            'secondsToInclude', stimulusDurationInSeconds, ...
            'emPathType', 'none' ...       
        );
        
        % Set up mosaic parameters. Here we integrate for the entire stimulus duration (100/1000)
        %
        % Keep mosaic size in lock step with stimulus
        rParams.mosaicParams = modifyStructParams(rParams.mosaicParams, ...
            'fieldOfViewDegs', rParams.spatialParams.fieldOfViewDegs, ...  
            'innerSegmentSizeMicrons',p.Results.innerSegmentSizeMicrons, ...
            'apertureBlur',p.Results.apertureBlur, ...
            'mosaicRotationDegs',p.Results.mosaicRotationDegs,...
            'coneDarkNoiseRate',p.Results.coneDarkNoiseRate,...
            'LMSRatio',p.Results.LMSRatio,...
            'coneSpacingMicrons', p.Results.coneSpacingMicrons, ...
            'conePacking', p.Results.conePacking, ...
        	'integrationTimeInSeconds', rParams.temporalParams.stimulusDurationInSeconds, ...
        	'isomerizationNoise', 'random',...              % select from {'random', 'frozen', 'none'}
        	'osNoise', 'random', ...                        % select from {'random', 'frozen', 'none'}
        	'osModel', 'Linear');
        
        % Make sure mosaic noise parameters match the frozen noise flag
        % passed in.  Doing this here means that things work on down the
        % chain, while if we don't then there is a problem because routines
        % create the wrong directory.
        if (p.Results.freezeNoise)
            if (strcmp(rParams.mosaicParams.isomerizationNoise, 'random'))
                rParams.mosaicParams.isomerizationNoise = 'frozen';
            end
            if (strcmp(rParams.mosaicParams.osNoise, 'random'))
                rParams.mosaicParams.osNoise = 'frozen';
            end
        end

        % Parameters that define the LM instances we'll generate here
        %
        % Use default LMPlane.
        testDirectionParams = instanceParamsGenerate;
        testDirectionParams = modifyStructParams(testDirectionParams, ...
            'trialsNum', p.Results.nTrainingSamples, ...
        	'startAngle', 45, ...
        	'deltaAngle', 90, ...
        	'nAngles', 1, ...
            'nContrastsPerDirection', p.Results.nContrastsPerDirection, ...
            'lowContrast', p.Results.lowContrast, ...
        	'highContrast', p.Results.highContrast, ...
        	'contrastScale', p.Results.contrastScale ...                       % choose between 'linear' and 'log'
            );
        
        % Parameters related to how we find thresholds from responses
        % Use default
        thresholdParams = thresholdParamsGenerate;
        thresholdParams.criterionFraction = p.Results.thresholdCriterionFraction;
        
        %% Compute response instances
        if (p.Results.useTrialBlocks)
            if (p.Results.useTrialBlocks == -1)
                trialBlocks = -1;
            else
                desiredTrialsPerBlock = p.Results.nTrialsPerBlock;
                trialBlocks = round(testDirectionParams.trialsNum/desiredTrialsPerBlock);
            end
        else
            trialBlocks = 1;
        end
        if (p.Results.computeResponses)
           t_coneCurrentEyeMovementsResponseInstances(...
               'rParams',rParams,...
               'testDirectionParams',testDirectionParams,...
               'compute',true,...
               'visualizedResponseNormalization', p.Results.visualizedResponseNormalization, ...
               'visualizeResponses',p.Results.visualizeResponses, ...
               'generatePlots',p.Results.generatePlots,...
               'freezeNoise',p.Results.freezeNoise,...
               'trialBlocks',trialBlocks);
        end
        
        %% Find performance, template max likeli
        thresholdParams.method = 'mlpt';
        if (p.Results.findPerformance)
            t_colorDetectFindPerformance('rParams',rParams,'testDirectionParams',testDirectionParams,'thresholdParams',thresholdParams,'compute',true,'plotSvmBoundary',false,'plotPsychometric',false,'freezeNoise',p.Results.freezeNoise);
        end
        
        %% Fit psychometric functions
        if (p.Results.fitPsychometric)
            banksEtAlReplicate.cyclesPerDegree(ll,cc) = p.Results.cyclesPerDegree(cc);
            thresholdParams.method = 'mlpt';
            banksEtAlReplicate.mlptThresholds(ll,cc) = t_plotDetectThresholdsOnLMPlane('rParams',rParams,'instanceParams',testDirectionParams,'thresholdParams',thresholdParams, ...
                'plotPsychometric',p.Results.generatePlots & p.Results.plotPsychometric,'plotEllipse',false);
            %close all;
        end
    end
end

%% Write out the data
%
% This read and write does not distinguish the number of backgrounds
% studied, and so can screw up if the number of backgrounds changes 
% between a run that generated the data and one that read it back.  If
% everything else is in place, it is quick to regenerate the data by just
% doing the fit psychometric step, which is pretty quick.
if (p.Results.fitPsychometric)
    fprintf('Writing performance data ... ');
    paramsList = {rParams.topLevelDirParams, rParams.mosaicParams, rParams.oiParams, rParams.spatialParams,  rParams.temporalParams, thresholdParams};
    rwObject = IBIOColorDetectReadWriteBasic;
    writeProgram = mfilename;
    rwObject.write('banksEtAlReplicate',banksEtAlReplicate,paramsList,writeProgram);
    fprintf('done\n');
end

%% Get performance data
fprintf('Reading performance data ...');
paramsList = {rParams.topLevelDirParams, rParams.mosaicParams, rParams.oiParams, rParams.spatialParams,  rParams.temporalParams, thresholdParams};
rwObject = IBIOColorDetectReadWriteBasic;
writeProgram = mfilename;
banksEtAlReplicate = rwObject.read('banksEtAlReplicate',paramsList,writeProgram);
fprintf('done\n');

%% Output validation data
if (nargout > 0)
    validationData.cyclesPerDegree = banksEtAlReplicate.cyclesPerDegree;
    validationData.mlptThresholds = banksEtAlReplicate.mlptThresholds;
    validationData.luminances = p.Results.luminances;
    extraData.paramsList = paramsList;
    extraData.p.Results = p.Results;
end

%% Make a plot of CSFs
%
% The way the plot is coded counts on the test contrasts never changing
% across the conditions, which we could explicitly check for here.
if (p.Results.generatePlots & p.Results.plotCSF)  
    hFig = figure; clf; hold on
    fontBump = 4;
    markerBump = -4;
    set(gcf,'Position',[100 100 450 650]);
    set(gca,'FontSize', rParams.plotParams.axisFontSize+fontBump);
    theColors = ['r' 'g' 'b'];
    legendStr = cell(length(p.Results.luminances),1);
    for ll = 1:length(p.Results.luminances)
        theColorIndex = rem(ll,length(theColors)) + 1;
        plot(banksEtAlReplicate.cyclesPerDegree(ll,:),1./[banksEtAlReplicate.mlptThresholds(ll,:).thresholdContrasts]*banksEtAlReplicate.mlptThresholds(1).testConeContrasts(1), ...
            [theColors(theColorIndex) 'o-'],'MarkerSize',rParams.plotParams.markerSize+markerBump,'MarkerFaceColor',theColors(theColorIndex),'LineWidth',rParams.plotParams.lineWidth);  
        legendStr{ll} = sprintf('%0.1f cd/m2',p.Results.luminances(ll));
        
    end
    set(gca,'XScale','log');
    set(gca,'YScale','log');
    xlabel('Log10 Spatial Frequency (cpd)', 'FontSize' ,rParams.plotParams.labelFontSize+fontBump, 'FontWeight', 'bold');
    ylabel('Log10 Contrast Sensitivity', 'FontSize' ,rParams.plotParams.labelFontSize+fontBump, 'FontWeight', 'bold');
    xlim([1 100]); ylim([10 10000]);
    legend(legendStr,'Location','NorthEast','FontSize',rParams.plotParams.labelFontSize+fontBump);
    box off; grid on
    titleStr1 = 'Computational Observer CSF';
    titleStr2 = sprintf('Blur: %d, Aperture Blur: %d',p.Results.blur, p.Results.apertureBlur);
    title({titleStr1 ; titleStr2});
        
    % Write out the figure
    rwObject.write('banksEtAlReplicate',hFig,paramsList,writeProgram,'Type','figure')
end



