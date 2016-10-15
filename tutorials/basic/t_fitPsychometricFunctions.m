function validationData = t_fitPsychometricFunctions(varargin)
% validationData = t_fitPsychometricFuncions(varargin)
%
% Read classification performance data generated by
%   t_colorDetectFindPerformance
% Plot the psychometric functions with a fit Weibull, which is used to find the threshold in each color direction.
%
% Key/value pairs
%   'rParams' - Value the is the rParams structure to use
%   'instanceParams' - Value is the instanceParams structure to use
%   'thresholdParams' - Value is the thresholdParams structure to use
%   'setRngSeed' - true/false (default true).  Set the rng seed to a
%        value so output is reproducible.
%   'generatePlots' - true/false (default true).  Produce
%       psychometric function output graphs.
%   'delete' - true/false (default false).  Delete the output
%        files.  Not yet implemented.

%% Parse input
p = inputParser;
p.addParameter('rParams',[],@isemptyorstruct);
p.addParameter('instanceParams',[],@isemptyorstruct);
p.addParameter('thresholdParams',[],@isemptyorstruct);
p.addParameter('setRng',true,@islogical);
p.addParameter('generatePlots',true,@islogical);
p.addParameter('delete',false',@islogical);
p.parse(varargin{:});
rParams = p.Results.rParams;
instanceParams = p.Results.instanceParams;
thresholdParams = p.Results.thresholdParams;

%% Clear
if (nargin == 0)
    ieInit; close all;
end

%% Fix random number generator so we can validate output exactly
if (p.Results.setRng)
    rng(1);
end

%% Get the parameters we need
%
% t_colorGaborResponseGenerationParams returns a hierarchical struct of
% parameters used by a number of tutorials and functions in this project.
if (isempty(rParams))
    rParams = responseParamsGenerate;
    
    % Override some defult parameters
    %
    % Set duration equal to sampling interval to do just one frame.
    rParams.temporalParams.simulationTimeStepSecs = 200/1000;
    rParams.temporalParams.stimulusDurationInSeconds = rParams.temporalParams.simulationTimeStepSecs;
    rParams.temporalParams.stimulusSamplingIntervalInSeconds = rParams.temporalParams.simulationTimeStepSecs;
    rParams.temporalParams.secondsToInclude = rParams.temporalParams.simulationTimeStepSecs;
    rParams.temporalParams.eyesDoNotMove = true;
    
    rParams.mosaicParams.timeStepInSeconds = rParams.temporalParams.simulationTimeStepSecs;
    rParams.mosaicParams.integrationTimeInSeconds = rParams.mosaicParams.timeStepInSeconds;
    rParams.mosaicParams.isomerizationNoise = true;
    rParams.mosaicParams.osNoise = true;
    rParams.mosaicParams.osModel = 'Linear';
end

%% Parameters that define the LM instances we'll generate here
%
% Make these numbers in the struct small (trialNum = 2, deltaAngle = 180,
% nContrastsPerDirection = 2) to run through a test quickly.
if (isempty(instanceParams))
    instanceParams = instanceParamsGenerate;
end

%% Parameters related to how we find thresholds from responses
if (isempty(thresholdParams))
    thresholdParams = thresholdParamsGenerate;
end

%% Set up the rw object for this program
rwObject = IBIOColorDetectReadWriteBasic;
readProgram = 't_colorDetectFindPerformance';
writeProgram = mfilename;

%% Read performance data
%
% We need this both for computing and plotting, so we just do it
paramsList = {rParams.spatialParams, rParams.temporalParams, rParams.oiParams, rParams.mosaicParams, rParams.backgroundParams, instanceParams, thresholdParams};
performanceData = rwObject.read('performanceData',paramsList,readProgram);

% If everything is working right, these check parameter structures will
% match what we used to specify the file we read in.
%
% SHOULD ACTUALLY CHECK FOR EQUALITY HERE.  Should be able to use
% RecursivelyCompareStructs to do so.
rParamsCheck = performanceData.rParams;
instanceParamsCheck = performanceData.instanceParams;
thresholdParamsCheck = performanceData.thresholdParams;

%% Extract data from loaded struct into convenient form
testContrasts = performanceData.testContrasts;
testConeContrasts = performanceData.testConeContrasts;
fitContrasts = logspace(log10(min(testContrasts)),log10(max(testContrasts)),100)';
nTrials = instanceParams.trialsNum;

%% Fit psychometric functions
%
% And make a plot of each along with its fit
for ii = 1:size(performanceData.testConeContrasts,2)
    % Get the performance data for this test direction, as a function of
    % contrast.
    thePerformance = squeeze(performanceData.percentCorrect(ii,:));
    theStandardError = squeeze(performanceData.stdErr(ii, :));
    
    % Fit psychometric function and find threshold.
    %
    % The work is done by singleThresholdExtraction, which itself calls the
    % Palemedes toolbox.  The Palemedes toolbox is included in the external
    % subfolder of the Isetbio distribution.
    [tempThreshold,fitFractionCorrect(:,ii),psychometricParams{ii}] = ...
        singleThresholdExtraction(testContrasts,thePerformance,thresholdParams.criterionFraction,nTrials,fitContrasts);
    thresholdContrasts(ii) = tempThreshold;
    
    % Convert threshold contrast to threshold cone contrasts
    thresholdConeContrasts(:,ii) = testConeContrasts(:,ii)*thresholdContrasts(ii);
end

%% Validation data
if (nargout > 0)
    validationData.testContrasts = testContrasts;
    validationData.testConeContrasts = testConeContrasts;
    validationData.thresholdContrasts = thresholdContrasts;
    validationData.thresholdConeContrasts = thresholdConeContrasts;
end

%% Plot psychometric functions
if (p.Results.generatePlots)
    for ii = 1:size(performanceData.testConeContrasts,2)    
        % Make the plot for this test direction
        hFig = figure; hold on
        set(gca,'FontSize',rParams.plotParams.axisFontSize);
        errorbar(log10(testContrasts), thePerformance, theStandardError, 'ro', 'MarkerSize', rParams.plotParams.markerSize, 'MarkerFaceColor', [1.0 0.5 0.50]);
        plot(log10(fitContrasts),fitFractionCorrect(:,ii),'r','LineWidth', 2.0);
        plot(log10(thresholdContrasts(ii))*[1 1],[0 thresholdParams.criterionFraction],'b', 'LineWidth', 2.0);
        axis 'square'
        set(gca, 'YLim', [0 1.0],'XLim', log10([testContrasts(1) testContrasts(end)]), 'FontSize', 14);
        xlabel('contrast', 'FontSize' ,rParams.plotParams.labelFontSize, 'FontWeight', 'bold');
        ylabel('percent correct', 'FontSize' ,rParams.plotParams.labelFontSize, 'FontWeight', 'bold');
        box off; grid on
        title({sprintf('LMangle = %2.1f deg, LMthreshold (%0.4f%%,%0.4f%%)', atan2(testConeContrasts(2,ii), testConeContrasts(1,ii))/pi*180, ...
            100*thresholdContrasts(ii)*testConeContrasts(1,ii), 100*thresholdContrasts(ii)*testConeContrasts(2,ii)) ; ''}, ...
            'FontSize',rParams.plotParams.titleFontSize);
        rwObject.write(sprintf('LMPsychoFunctions_%d',ii),hFig,paramsList,writeProgram,'Type','figure');    
    end
end


