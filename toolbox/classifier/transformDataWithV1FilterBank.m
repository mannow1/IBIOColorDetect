function [noStimData, stimData] = transformDataWithV1FilterBank(noStimData, stimData, V1filterBank, standardize)
%
% 1/17/17   NPC  wrote it


if (ndims(noStimData.responseInstanceArray.theMosaicIsomerizations) ~= 3)
    error('transformDataWithV1FilterBank not yet implemented for other than 3D response arrays, ndims = %d\n', ndims(noStimData.responseInstanceArray.theMosaicIsomerizations));
end

% Subtract mean response from noStimData
meanNoStimIsomerizationsLevels = mean(mean(noStimData.responseInstanceArray.theMosaicIsomerizations,3),1);
meanNoStimPhotocurrentsLevels = mean(mean(noStimData.responseInstanceArray.theMosaicPhotocurrents,3),1);

noStimData.responseInstanceArray.theMosaicIsomerizations = ...
    bsxfun(@minus,noStimData.responseInstanceArray.theMosaicIsomerizations, meanNoStimIsomerizationsLevels);
noStimData.responseInstanceArray.theMosaicPhotocurrents = ...
    bsxfun(@minus,noStimData.responseInstanceArray.theMosaicPhotocurrents, meanNoStimPhotocurrentsLevels);

stimData.responseInstanceArray.theMosaicIsomerizations = ...
    bsxfun(@minus,stimData.responseInstanceArray.theMosaicIsomerizations, meanNoStimIsomerizationsLevels);
stimData.responseInstanceArray.theMosaicPhotocurrents = ...
    bsxfun(@minus,stimData.responseInstanceArray.theMosaicPhotocurrents, meanNoStimPhotocurrentsLevels);

% Compute the energy response of the V1 filter bank
netWeight = sqrt(sum(V1filterBank.cosPhasePoolingWeights(:).^2 + V1filterBank.sinPhasePoolingWeights(:).^2));

nTrials = size(noStimData.responseInstanceArray.theMosaicIsomerizations,1);
nTimeBins = size(noStimData.responseInstanceArray.theMosaicIsomerizations,3);
V1filterBank.cosPhasePoolingWeights = repmat(V1filterBank.cosPhasePoolingWeights, [nTrials 1 nTimeBins]);
V1filterBank.sinPhasePoolingWeights = repmat(V1filterBank.sinPhasePoolingWeights, [nTrials 1 nTimeBins]);

cosFilterLinearActivation = squeeze(sum(noStimData.responseInstanceArray.theMosaicIsomerizations .* V1filterBank.cosPhasePoolingWeights, 2));
sinFilterLinearActivation = squeeze(sum(noStimData.responseInstanceArray.theMosaicIsomerizations .* V1filterBank.sinPhasePoolingWeights, 2));
noStimData.responseInstanceArray.theMosaicIsomerizations = 1/netWeight * sqrt(cosFilterLinearActivation.^2 + sinFilterLinearActivation.^2);

cosFilterLinearActivation = squeeze(sum(noStimData.responseInstanceArray.theMosaicPhotocurrents .* V1filterBank.cosPhasePoolingWeights, 2));
sinFilterLinearActivation = squeeze(sum(noStimData.responseInstanceArray.theMosaicPhotocurrents .* V1filterBank.sinPhasePoolingWeights, 2));
noStimData.responseInstanceArray.theMosaicPhotocurrents = 1/netWeight * sqrt(cosFilterLinearActivation.^2 + sinFilterLinearActivation.^2);

cosFilterLinearActivation = squeeze(sum(stimData.responseInstanceArray.theMosaicIsomerizations .* V1filterBank.cosPhasePoolingWeights, 2));
sinFilterLinearActivation = squeeze(sum(stimData.responseInstanceArray.theMosaicIsomerizations .* V1filterBank.sinPhasePoolingWeights, 2));
stimData.responseInstanceArray.theMosaicIsomerizations = 1/netWeight * sqrt(cosFilterLinearActivation.^2 + sinFilterLinearActivation.^2);

cosFilterLinearActivation = squeeze(sum(stimData.responseInstanceArray.theMosaicPhotocurrents .* V1filterBank.cosPhasePoolingWeights, 2));
sinFilterLinearActivation = squeeze(sum(stimData.responseInstanceArray.theMosaicPhotocurrents .* V1filterBank.sinPhasePoolingWeights, 2));
stimData.responseInstanceArray.theMosaicPhotocurrents = 1/netWeight * sqrt(cosFilterLinearActivation.^2 + sinFilterLinearActivation.^2);

%% Standardize the data
if (standardize)
    % zero mean, unit std
    noStimData.responseInstanceArray.theMosaicIsomerizations = standardizeResponses(noStimData.responseInstanceArray.theMosaicIsomerizations);
    noStimData.responseInstanceArray.theMosaicPhotocurrents = standardizeResponses(noStimData.responseInstanceArray.theMosaicPhotocurrents);
    stimData.responseInstanceArray.theMosaicIsomerizations = standardizeResponses(stimData.responseInstanceArray.theMosaicIsomerizations);
    stimData.responseInstanceArray.theMosaicPhotocurrents = standardizeResponses(stimData.responseInstanceArray.theMosaicPhotocurrents);
end

isomerizationsRange = [ ...
    min([min(stimData.responseInstanceArray.theMosaicIsomerizations(:)) min(noStimData.responseInstanceArray.theMosaicIsomerizations(:))]) 
    max([max(stimData.responseInstanceArray.theMosaicIsomerizations(:)) max(noStimData.responseInstanceArray.theMosaicIsomerizations(:))])];

photocurrentsRange = [...
    min([min(stimData.responseInstanceArray.theMosaicPhotocurrents(:)) min(noStimData.responseInstanceArray.theMosaicPhotocurrents(:))]) ...
    max([max(stimData.responseInstanceArray.theMosaicPhotocurrents(:)) max(noStimData.responseInstanceArray.theMosaicPhotocurrents(:))])];

hFig = figure(1234); clf;
set(hFig, 'Position', [10 10 1600 1000]);

subplot(2,2,1);
stairs(1:nTimeBins, noStimData.responseInstanceArray.theMosaicIsomerizations', 'k-')
set(gca, 'YLim', isomerizationsRange);
title('isomerizations (noStim)');

subplot(2,2,2);
stairs(1:nTimeBins, stimData.responseInstanceArray.theMosaicIsomerizations', 'k-')
set(gca, 'YLim', isomerizationsRange);
title(sprintf('isomerizations (c = %2.4f)', stimData.testContrast));

subplot(2,2,3);
plot(1:nTimeBins, noStimData.responseInstanceArray.theMosaicPhotocurrents, 'k-')
set(gca, 'YLim', photocurrentsRange);
title('photocurrents (noStim)');

subplot(2,2,4);
plot(1:nTimeBins, stimData.responseInstanceArray.theMosaicPhotocurrents, 'k-')
set(gca, 'YLim', photocurrentsRange);
title(sprintf('iphotocurrents (c = %2.4f)', stimData.testContrast));
drawnow;

end

function responses = standardizeResponses(responses)
    stdDimensionIndex = 2;
    s = std(responses, 0, stdDimensionIndex);
    index = find(s ~= 0);
    responses = responses(index,:);
    s = s(index);
    m = mean(responses,stdDimensionIndex);
    responses = (responses - repmat(m,1,size(responses,stdDimensionIndex))) ./ repmat(s,1, size(responses,stdDimensionIndex));
end

