function testMeanOTFmodels

    wavelengthsListToCompute = [400:10:700];

    recomputeOTFdata = ~true;
    if (recomputeOTFdata)
        centeringWavelength = 550;
        targetPupilDiamMM = 3.0;
        wavefrontSpatialSamples = 201;
        psfRange = 6*[-1 1];
        otfRange = [0 100];
        d = computeAllOTFs(wavelengthsListToCompute,centeringWavelength,targetPupilDiamMM, wavefrontSpatialSamples, psfRange, otfRange);
    else
        fprintf('Loading data\n');
        d = loadOTFs();
    end
    
    % Extract 1D OTF slices
    [xSfCyclesDeg, meanZcoeffMTFSlicesX, meanSubjectMTFSlicesX, subjectMTFSlicesX, ...
        meanZcoeffMTFSlicesY, meanSubjectMTFSlicesY, subjectMTFSlicesY] = ...
        extractMTFslices(d.xSfCyclesDeg, d.meanZcoeffOTF, d.meanSubjectOTF, d.subjectOTF);
    
    targetWavelength = 550;
    
    fprintf('Computing PCA on PSFs\n');
    % compute PSF matching scores
    pcaProjectionSpaceDim = size(d.subjectPSF,1);
    [PCAprojections, meanZcoeffProjection] = computePCAprojections(d.subjectPSF, d.meanZcoeffPSF, pcaProjectionSpaceDim);

    psfWaveWeightingSigma = 50*100;
    psfScores = computePSFmatchScore(PCAprojections, meanZcoeffProjection, wavelengthsListToCompute, targetWavelength, psfWaveWeightingSigma);

    bestSubjects = [132 96]
    
    %[98 132 55 99 172 198 186 66];
    
    % compute OTF matching scores
    otfWaveWeightingSigma = 10; % input('Enter spectral sigma for the OTF weigting:');
    diagonalSigma = 0.015;        % input('Enter diagonal sigma :');
    diagonalSlopes = 5:10:85;     % [25:10:65];
    otfScores = computeOTFmatchScore(d.subjectOTF, d.meanSubjectOTF, wavelengthsListToCompute, targetWavelength, otfWaveWeightingSigma);
    plotScoresNew(otfScores, psfScores, otfWaveWeightingSigma, diagonalSigma, diagonalSlopes);
     
    while (1)   
        whichSubject = input('Subject id to display:');
        plotRankedSubjectData(whichSubject, wavelengthsListToCompute, xSfCyclesDeg, d.xMinutes, ...
                meanZcoeffMTFSlicesX, meanSubjectMTFSlicesX, subjectMTFSlicesX, ...
                meanZcoeffMTFSlicesY, meanSubjectMTFSlicesY, subjectMTFSlicesY, ...
                squeeze(d.subjectPSF(whichSubject,:,:,:)), d.meanZcoeffPSF);
    end
    
    %plot2DPSFAndOTF(wavelengthsListToCompute, d.xMinutes, d.yMinutes,  d.xSfCyclesDeg, d.ySfCyclesDeg, d.meanZcoeffPSF, d.meanZcoeffOTF, d.meanSubjectOTF);
end

function [rankedSubjectScores, rankedSubjects, highlightedSubjectsNum] = computeComboScore(xScore,yScore,diagonalSigma, alphaDegs)
    alpha = tand(alphaDegs);
    comboScore = exp(-0.5*(alpha*xScore-yScore).^2/diagonalSigma) .* (alpha*xScore.*yScore);
    comboScore = comboScore/max(comboScore(:));
    [rankedSubjectScores, rankedSubjects] = sort(comboScore, 'descend');
    highlightedSubjectsNum = numel(find(rankedSubjectScores/max(rankedSubjectScores) > 0.5));
    
end

function [rankedSubjects, rankedSubjectScores] = plotScoresNew(otfScores, psfScores, otfWaveWeightingSigma, diagonalSigma, diagonalSlopes)

    slopeColors = brewermap(numel(diagonalSlopes), 'Set1');

    hFig = figure(32); clf;
    set(hFig, 'Position', [10 10 820 820], 'Color', [1 1 1]);
    
    hold on;
    for slopeIndex = 1:numel(diagonalSlopes)
        slope = diagonalSlopes(slopeIndex);
        if (slope < 45)
            plot([0.03 1], [0.03 1]*tand(slope), '-', 'Color', squeeze(slopeColors(slopeIndex,:)), 'LineWidth', 1.5);
        else
            plot([0.03 1]/tand(slope), [0.03 1], '-', 'Color', squeeze(slopeColors(slopeIndex,:)), 'LineWidth', 1.5);
        end
    end
    
    for slopeIndex = 1:numel(diagonalSlopes)
        [rankedSubjectScores, rankedSubjects, highlightedSubjectsNum] = computeComboScore(otfScores,psfScores,diagonalSigma, diagonalSlopes(slopeIndex));
        
        if (slopeIndex == 1)
            for kk = 1:numel(rankedSubjects)
                k = rankedSubjects(kk);
                text(otfScores(k), psfScores(k), sprintf('%d', k), 'Color', 'k', 'FontSize', 12);
            end
        end
        
        for kk = 1:highlightedSubjectsNum
            k = rankedSubjects(kk);
            text(otfScores(k), psfScores(k), sprintf('%d', k), 'Color', squeeze(slopeColors(slopeIndex,:)), 'FontSize', 12);
        end
    
    end
    xlabel('otf score');
    ylabel('psf score');
    set(gca, 'XTick', 0:0.1:1, 'YTick', 0:0.1:1, 'XLim', [-0.05 1.05], 'YLim', [-0.05 1.05],'FontSize', 16);
    axis 'square'; axis 'xy'; grid 'on'; box 'on'
    NicePlot.exportFigToPDF(sprintf('scores_otfSigma_%2_2f.pdf', otfWaveWeightingSigma), hFig, 300);
end

function [rankedSubjects, rankedSubjectScores] = plotScores(otfScores, psfScores, diagonalSigma, diagonalSlopeDegs)
    
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
           'rowsNum', 2, ...
           'colsNum', 1, ...
           'heightMargin',   0.08, ...
           'widthMargin',    0.03, ...
           'leftMargin',     0.03, ...
           'rightMargin',    0.006, ...
           'bottomMargin',   0.1, ...
           'topMargin',      0.03);
      
    comboScore = computeComboScore(otfScores,psfScores,diagonalSigma, diagonalSlopeDegs);
    
    [rankedSubjectScores, rankedSubjects] = sort(comboScore, 'descend');
    rankedSubjects(1:10)
    rankedSubjects(numel(rankedSubjects):-1:(numel(rankedSubjects)-10))
    
    highlightedSubjectsNum = 50;
    
    hFig = figure(33); clf;
    set(hFig, 'Position', [10 10 1670 820], 'Color', [1 1 1]);

    pos1 = subplotPosVectors(1,1).v;
    subplot('Position', pos1);
    x = 0:0.01:1; y = x;
    [X,Y] = meshgrid(x,y);
    Z = computeComboScore(X,Y,diagonalSigma,diagonalSlopeDegs);
    imagesc(x,y,Z);
    hold on
    for k = highlightedSubjectsNum+1:numel(otfScores)
        text(otfScores(k), psfScores(k), sprintf('%d', k), 'Color', 'b');
    end
    for kk = 1:highlightedSubjectsNum
        k = rankedSubjects(kk);
        text(otfScores(k), psfScores(k), sprintf('%d', k), 'Color', 'r');
    end
    
    xlabel('otf score');
    ylabel('psf score');
    set(gca, 'XTick', 0:0.1:1, 'YTick', 0:0.1:1, 'XLim', [-0.05 1.05], 'YLim', [-0.05 1.05], 'CLim',[0 max(Z(:))],'FontSize', 16);
    axis 'square'; axis 'xy'; grid 'on'; box 'on'
    cmap = brewermap(1024, 'Greys');
    colormap((1-cmap).^0.5);
    
    
    pos = subplotPosVectors(2,1).v;
    subplot('Position', pos);
    plot((1:numel(rankedSubjectScores))/numel(rankedSubjectScores), rankedSubjectScores(:)/max(rankedSubjectScores), 'ko', 'MarkerSize', 8, 'MarkerFaceColor', [0.8 0.8 0.8]);
    
    hold on;
    for k = 1:numel(rankedSubjectScores)
        switch (mod(k-1,4))
            case 0 
                yoffset = 0.1;
            case 1
                yoffset = -0.1;
            case 2
                yoffset = 0.05;
            case 3
                yoffset = -0.05;
        end

        if (k <=highlightedSubjectsNum)
            color = 'r';
        else
            color = 'b';
        end
        plot(k/numel(rankedSubjectScores)*[1 1], rankedSubjectScores(k)/max(rankedSubjectScores)+[0 yoffset], 'k-');
        text(k/numel(rankedSubjectScores), rankedSubjectScores(k)/max(rankedSubjectScores)+yoffset, sprintf('%d', rankedSubjects(k)), 'Color', color);
    end
    xTicks = 0:0.05:1;
    yTicks = (0:0.1:1.0);
    set(gca, 'XTick', xTicks, 'XTickLabel', sprintf('%2.0f\n', xTicks*numel(rankedSubjectScores)), ...
        'YTick', yTicks, 'XTickLabel', {}, 'XLim', [0 1+1/200], 'YLim', [-0.1 1.1], ...
        'YTickLabel', sprintf('%1.1f\n',yTicks*max(rankedSubjectScores)),'FontSize', 16);
    grid 'on'; box 'on'
    ylabel('combo score');
    
end

function [subjectPCAprojections, meanZcoeffPCAProjection] = computePCAprojections(subjectPSFs, meanZcoeffPSF, projectionSpaceDim)

    subjectsNum = size(subjectPSFs,1);
    N = size(subjectPSFs,2)*size(subjectPSFs,3);
    nWaves = size(subjectPSFs,4);
    
    subjectPCAprojections = zeros(nWaves,subjectsNum, projectionSpaceDim);
    meanZcoeffPCAProjection = zeros(nWaves, projectionSpaceDim);
    
    for iW = 1:nWaves 
        waveSubjectPSFs = squeeze(subjectPSFs(:,:,:,iW));
        waveSubjectPSFs = reshape(waveSubjectPSFs, [subjectsNum N]);
        
        waveMeanZcoeffPSF = squeeze(meanZcoeffPSF(:,:,iW));
        waveMeanZcoeffPSF = reshape(waveMeanZcoeffPSF, [1 N]);
        
        [~, ~, v] = svd(waveSubjectPSFs, 'econ');
%         reconstructedPSFs = u * s *v';
%         varianceExplained = (diag(s)).^2;
%         varianceExplained = varianceExplained / sum(varianceExplained);
%         explained = cumsum(varianceExplained);
%         explained = explained / max(explained)*100;

        
        for subjectIndex = 1:subjectsNum
           subjectPCAprojections(iW,subjectIndex,:) = squeeze(waveSubjectPSFs(subjectIndex,:) * v(:,1:projectionSpaceDim));
        end
        
        meanZcoeffPCAProjection(iW,:) = waveMeanZcoeffPSF * v(:,1:projectionSpaceDim);
    end
end

function psfScores = computePSFmatchScore(PCAprojections, meanZcoeffProjection, wavelengths, targetWavelength, otfWaveWeightingSigma)

    bias = 1;
    spectralWeighting = bias + (1-exp(-0.5*((wavelengths-targetWavelength)/otfWaveWeightingSigma).^2));
    spectralWeighting = spectralWeighting / max(spectralWeighting);
    
    figure(3); clf
    subplot(1,2,1);
    stem(wavelengths, spectralWeighting, 'filled');
    set(gca, 'YLim', [-0.05 1.05], 'FontSize', 14);
    set(gca, 'XLim', [390 710]);
    axis 'square'; box on; grid on;
    xlabel('wavelength (nm)');
    ylabel('PSF weighting');
    drawnow
    
    nWaves = size(meanZcoeffProjection,1);
    for iW = 1:nWaves 
        targetCoeffs = squeeze(meanZcoeffProjection(iW,:));
        subjectCoeffs = squeeze(PCAprojections(iW,:,:));
        distances(iW,:) = spectralWeighting(iW) * sqrt(sum((bsxfun(@minus, subjectCoeffs, targetCoeffs)).^2,2));
    end
    weightedMeanDistances = squeeze(sum(distances,1));
    
    psfRMS = (weightedMeanDistances-min(weightedMeanDistances))/(max(weightedMeanDistances)-min(weightedMeanDistances));
    psfScores = 1-psfRMS;
end

function radialMap = radiallyAveragedXYZMap(map)
    mid = floor(size(map,1)/2);
    [x,y] = meshgrid(-mid:mid, -mid:mid);
    r = sqrt(x.^2 + y.^2);
    mask = squeeze(map(:,:,1))*0;
    mask(r<=mid) = 1;
    
    deltaAngle = 5;
    angles = 0:deltaAngle:360;
    radialMap = map*0;
    
    parfor iW = 1:size(map,3)
        waveMap = squeeze(map(:,:,iW));
        waveMap = waveMap .* mask;
        radialWaveMap = waveMap * 0;
        for iAngle = 1:numel(angles)
            radialWaveMap = radialWaveMap + imrotate(waveMap,angles(iAngle), 'bilinear', 'crop');
        end
        radialMap(:,:,iW) = radialWaveMap / (numel(angles));
    end
end

function otfScores = computeOTFmatchScore(subjectOTFs, targetOTF, wavelengths, targetWavelength, otfWaveWeightingSigma)

    bias = 0.2;
    spectralWeighting = bias + (1-bias)*exp(-0.5*((wavelengths-targetWavelength)/otfWaveWeightingSigma).^2);
    hFig = figure(3); 
    subplot(1,2,2)
    stem(wavelengths, spectralWeighting, 'filled');
    set(gca, 'YLim', [-0.05 1.05], 'FontSize', 14);
    set(gca, 'XLim', [390 710]);
    axis 'square'; box on; grid on;
    xlabel('wavelength (nm)');
    ylabel('OTF weighting');
    NicePlot.exportFigToPSF(sprintf('weights_%2_2f.pdf',otfWaveWeightingSigma), hFig, 300);
    drawnow;
    
    nSubjects = size(subjectOTFs,1);
    otfRMS = zeros(1, nSubjects);

    for iSubject = 1:nSubjects
        thisSubjectOTF = squeeze(subjectOTFs(iSubject,:,:,:));
        residual = (abs(thisSubjectOTF)-abs(targetOTF)).^2;
        weightedSummedResidual = 0;
        for iW = 1:numel(spectralWeighting)
            weightedSummedResidual = weightedSummedResidual + spectralWeighting(iW) * sum(sum(squeeze(residual(:,:,iW))));
        end
        otfRMS(iSubject) = sqrt(weightedSummedResidual/sum(spectralWeighting));
    end

    otfRMS = (otfRMS-min(otfRMS))/(max(otfRMS)-min(otfRMS));
    otfScores = 1-otfRMS;
end

function [xSfCyclesDeg, meanZcoeffOTFSlicesX, meanSubjectOTFSlicesX, subjectOTFSlicesX, ...
          meanZcoeffOTFSlicesY, meanSubjectOTFSlicesY, subjectOTFSlicesY] = ...
    extractMTFslices( xSfCyclesDeg, meanZcoeffOTF, meanSubjectOTF, subjectOTF)
    midRow = floor(size(subjectOTF,2)/2)+1;
    
    meanZcoeffOTFSlicesX = abs(squeeze(meanZcoeffOTF(midRow,midRow:end,:)));
    meanSubjectOTFSlicesX = abs(squeeze(meanSubjectOTF(midRow,midRow:end,:)));
    subjectOTFSlicesX = abs(squeeze(subjectOTF(:,midRow,midRow:end,:)));
    
    meanZcoeffOTFSlicesY = abs(squeeze(meanZcoeffOTF(midRow:end,midRow,:)));
    meanSubjectOTFSlicesY = abs(squeeze(meanSubjectOTF(midRow:end,midRow,:)));
    subjectOTFSlicesY = abs(squeeze(subjectOTF(:,midRow:end,midRow,:)));
    
    xSfCyclesDeg = xSfCyclesDeg(midRow:end);

end

function plotRankedSubjectData(subjectIndex, wavelengthsListToCompute, ...
    xSfCyclesDeg, xMinutes, meanZcoeffOTFSlicesX, meanSubjectOTFSlicesX, subjectOTFSlicesX, ...
    meanZcoeffOTFSlicesY, meanSubjectOTFSlicesY, subjectOTFSlicesY, ...
    rankedSubjectPSF, meanZcoeffPSF)

    nWaves = size(subjectOTFSlicesX,3);
    waveStride = 3;
    subplotPosVectors = NicePlot.getSubPlotPosVectors(...
           'rowsNum', 3, ...
           'colsNum', floor(nWaves/waveStride), ...
           'heightMargin',   0.03, ...
           'widthMargin',    0.01, ...
           'leftMargin',     0.01, ...
           'rightMargin',    0.001, ...
           'bottomMargin',   0.01, ...
           'topMargin',      0.03);
       
    hFig = figure(1); clf;
    set(hFig, 'Position', [10 10 1670 600], 'Color', [1 1 1]);
    
    idx = find(wavelengthsListToCompute==550);
    targetMod = mod(idx-1,waveStride);
    
    iiw = 0;
    for iW = 1:nWaves 
        if (mod(iW-1,waveStride) ~= targetMod) || (iiw+1>size(subplotPosVectors,2))
            %fprintf('Skipping %dnm\n', wavelengthsListToCompute(iW));
            continue;
        end
        iiw = iiw + 1; 
        
        ySliceColor = [1 0 0];
        ySliceColor2 = [1 0.5 0.5];
        xSliceColor = [0. 0. 1.0];
        xSliceColor2 = [0.5 0.5 1.0];
        
        subplot('Position', subplotPosVectors(1,iiw).v);
        plot(xSfCyclesDeg, squeeze(meanSubjectOTFSlicesX(:,iW)), ':', 'Color', xSliceColor, 'LineWidth', 2.0);
        hold on;
        plot(xSfCyclesDeg, squeeze(meanSubjectOTFSlicesY(:,iW)), ':', 'Color', ySliceColor, 'LineWidth', 2.0);
        plot(xSfCyclesDeg, squeeze(subjectOTFSlicesX(subjectIndex,:,iW)), '-', 'Color', xSliceColor , 'LineWidth', 2.0);
        plot(xSfCyclesDeg, squeeze(subjectOTFSlicesY(subjectIndex,:,iW)), '-', 'Color', ySliceColor , 'LineWidth', 2.0);
        
        plot(xSfCyclesDeg, squeeze(subjectOTFSlicesX(1:2:end,:,iW)), '-', 'Color', [0.6 0.6 0.6]);
        plot(xSfCyclesDeg, squeeze(subjectOTFSlicesY(1:2:end,:,iW)), '-', 'Color', [0.6 0.6 0.6]);
        
        plot(xSfCyclesDeg, squeeze(subjectOTFSlicesX(subjectIndex,:,iW)), '-', 'Color', xSliceColor2 , 'LineWidth', 4.0);
        plot(xSfCyclesDeg, squeeze(subjectOTFSlicesY(subjectIndex,:,iW)), '-', 'Color', ySliceColor2 , 'LineWidth', 4.0);
        plot(xSfCyclesDeg, squeeze(meanSubjectOTFSlicesX(:,iW)), '-', 'Color', xSliceColor2, 'LineWidth', 4.0);
        plot(xSfCyclesDeg, squeeze(meanSubjectOTFSlicesY(:,iW)), '-', 'Color', ySliceColor2, 'LineWidth', 4.0);
        plot(xSfCyclesDeg, squeeze(meanSubjectOTFSlicesX(:,iW)), ':', 'Color', xSliceColor, 'LineWidth', 2.0);
        plot(xSfCyclesDeg, squeeze(meanSubjectOTFSlicesY(:,iW)), ':', 'Color', ySliceColor, 'LineWidth', 2.0);
        plot(xSfCyclesDeg, squeeze(subjectOTFSlicesX(subjectIndex,:,iW)), '-', 'Color', xSliceColor , 'LineWidth', 2.0);
        plot(xSfCyclesDeg, squeeze(subjectOTFSlicesY(subjectIndex,:,iW)), '-', 'Color', ySliceColor , 'LineWidth', 2.0);
        
        hold off
        set(gca, 'FontSize', 14, 'XTick', 0:20:100, 'XLim', [0 100], 'YLim', [0 1]);
        if (iW > 1)
            set(gca, 'YTickLabel', {});
            set(gca, 'XTickLabel', {});
        end
        axis 'square'
        grid on; box on;
        legend({'mean(x)', 'mean(y)', sprintf('#%d (x)', subjectIndex), sprintf('#%d (y)', subjectIndex)});
        title(sprintf('%d nm', wavelengthsListToCompute(iW)));
        
        
        subplot('Position', subplotPosVectors(2,iiw).v);
        thePSF = squeeze(rankedSubjectPSF(:,:,iW));
        imagesc(xMinutes, xMinutes, thePSF);
        hold on;
        plot([xMinutes(1) xMinutes(end)], [0 0], 'g-');
        plot([0 0], [xMinutes(1) xMinutes(end)],  'g-');
        hold off;
        axis 'image'; 
        if (iW > 1)
            set(gca, 'YTickLabel', {});
        end
        set(gca, 'XTickLabel', {});
        set(gca, 'FontSize', 12);
        title(sprintf('#%d PSF',subjectIndex));
        
        subplot('Position', subplotPosVectors(3,iiw).v);
        thePSF = squeeze(meanZcoeffPSF(:,:,iW));
        imagesc(xMinutes, xMinutes, thePSF);
        hold on;
        plot([xMinutes(1) xMinutes(end)], [0 0], 'g-');
        plot([0 0], [xMinutes(1) xMinutes(end)],  'g-');
        hold off;
        axis 'image'; 
        if (iW > 1)
            set(gca, 'YTickLabel', {});
        end
        set(gca, 'XTickLabel', {});
        set(gca, 'FontSize', 12);
        title('meanZ PSF');
        
    end
    colormap(bone(1024));
    
    NicePlot.exportFigToPNG(sprintf('subject%d.png', subjectIndex),hFig, 300);
end

function plot2DPSFAndOTF(wavelengthsListToCompute, xMinutes, yMinutes, xSfCyclesDeg, ySfCyclesDeg, thePSF, theOTF, theMeanSubjectOTF)
    figure(2); clf;
    nWaves = numel(wavelengthsListToCompute);
    
    for iW = 1:nWaves  
        subplot(3, nWaves,iW);
        imagesc(xMinutes, yMinutes, squeeze(thePSF(:,:,iW)));
        title(sprintf('%d nm', wavelengthsListToCompute(iW)));
        axis 'image'; xlabel('minutes');
        if (iW > 1)
            set(gca, 'YTickLabel', {});
        end
        set(gca, 'FontSize', 12);
        
        subplot(3, nWaves,iW+nWaves);
        imagesc(xSfCyclesDeg, ySfCyclesDeg, squeeze(theOTF(:,:,iW)));
        axis 'image'; xlabel('c/deg');
        if (iW > 1)
            set(gca, 'YTickLabel', {});
        end
        set(gca, 'FontSize', 12);
        
        subplot(3, nWaves,iW+2*nWaves);
        imagesc(xSfCyclesDeg, ySfCyclesDeg, squeeze(theMeanSubjectOTF(:,:,iW)));
        axis 'image'; xlabel('c/deg');
        if (iW > 1)
            set(gca, 'YTickLabel', {});
        end
        set(gca, 'FontSize', 12);
        
    end
    colormap(gray(1024));
end

function d = loadOTFs()
    load('allPSFdata.mat', ...
        'meanZcoeffPSF', 'meanZcoeffOTF',  ...
        'meanSubjectOTF',  'subjectPSF', 'subjectOTF', ...
        'xMinutes', 'yMinutes', 'xSfCyclesDeg', 'ySfCyclesDeg');
    

    d.xMinutes = xMinutes;
    d.yMinutes = yMinutes;
    d.xSfCyclesDeg = xSfCyclesDeg;
    d.ySfCyclesDeg = ySfCyclesDeg;
    d.meanZcoeffPSF = meanZcoeffPSF;
    d.meanZcoeffOTF = meanZcoeffOTF;
    d.meanSubjectOTF = meanSubjectOTF;
    d.subjectPSF = subjectPSF;
    d.subjectOTF = subjectOTF;

end

function d = computeAllOTFs(wavelengthsListToCompute,centeringWavelength,targetPupilDiamMM, wavefrontSpatialSamples, psfRange, otfRange)
    % Load the ZernikeCoeffs for the target pupil size
    [Zcoeffs_SampleMean, Zcoeffs_S, subject_coeffs] = wvfLoadThibosVirtualEyes(targetPupilDiamMM);
    ZcoeffSubjects = subject_coeffs.bothEyes;
    subjectsNum = size(ZcoeffSubjects,2);
    
    % Compute the meanZcoeff PSF and OTF
    fprintf('computing mean Zcoeff PSF/OTF\n');
    [meanZcoeffPSF, meanZcoeffOTF, xSfCyclesDeg, ySfCyclesDeg, xMinutes, yMinutes] = ...
        computePSFandOTF(Zcoeffs_SampleMean, wavelengthsListToCompute, wavefrontSpatialSamples, targetPupilDiamMM, centeringWavelength);
    
    % Only keep PSF data within the psfRange
    psfColsToKeep = find(abs(xMinutes) < max(psfRange));
    psfRowsToKeep = find(abs(yMinutes) < max(psfRange));
    xMinutes = xMinutes(psfColsToKeep);
    yMinutes = yMinutes(psfRowsToKeep);
    meanZcoeffPSF = meanZcoeffPSF(psfRowsToKeep, psfColsToKeep,:);
    
    % Only keep OTF data within the otfRange
    otfColsToKeep = find(abs(xSfCyclesDeg) < max(otfRange));
    otfRowsToKeep = find(abs(ySfCyclesDeg) < max(otfRange));
    xSfCyclesDeg  = xSfCyclesDeg(otfColsToKeep);
    ySfCyclesDeg  = ySfCyclesDeg(otfRowsToKeep);
    meanZcoeffOTF = meanZcoeffOTF(otfRowsToKeep, otfColsToKeep,:);
    
    % Preallocate memory to store the subject data
    subjectPSF = zeros(subjectsNum, size(meanZcoeffPSF,1), size(meanZcoeffPSF, 2), size(meanZcoeffPSF, 3));
    subjectOTF = zeros(subjectsNum, size(meanZcoeffOTF,1), size(meanZcoeffOTF, 2), size(meanZcoeffOTF, 3));
    
    % Compute individual subject data
    parfor subjectIndex = 1:subjectsNum
        fprintf('computing PSF/OTF for subject %d\n', subjectIndex);
        z = squeeze(ZcoeffSubjects(:,subjectIndex));    
        [psf, otf, ~, ~, ~, ~] = ...
            computePSFandOTF(z, wavelengthsListToCompute, wavefrontSpatialSamples, targetPupilDiamMM, centeringWavelength);
        subjectPSF(subjectIndex,:,:,:) = psf(psfRowsToKeep, psfColsToKeep,:);
        subjectOTF(subjectIndex,:,:,:) = otf(otfRowsToKeep, otfColsToKeep,:);
    end
    % Compute mean across subjects OTF and MTF
    meanSubjectOTF = squeeze(mean(subjectOTF,1));
    
    
    % Save data
    save('allPSFdata.mat', ...
        'meanZcoeffPSF', 'meanZcoeffOTF',  ...
        'meanSubjectOTF', 'subjectPSF', 'subjectOTF', ...
        'xMinutes', 'yMinutes', 'xSfCyclesDeg', 'ySfCyclesDeg', ...
        '-v7.3');
    fprintf('data saved\n');
    
    d.xMinutes = xMinutes;
    d.yMinutes = yMinutes;
    d.xSfCyclesDeg = xSfCyclesDeg;
    d.ySfCyclesDeg = ySfCyclesDeg;
    d.meanZcoeffPSF = meanZcoeffPSF;
    d.meanZcoeffOTF = meanZcoeffOTF;
    d.meanSubjectOTF = meanSubjectOTF;
    d.subjectPSF = subjectPSF;
    d.subjectOTF = subjectOTF;
end


function [PSFs, OTFs, xSfCyclesDeg, ySfCyclesDeg, xMinutes, yMinutes] = computePSFandOTF(Zcoeffs, wavelengthsListToCompute, wavefrontSpatialSamples, targetPupilDiamMM, centeringWavelength)
    %% Compute WVF
    umPerDegree = 300;
    theWVF = makeWVF(wavefrontSpatialSamples, Zcoeffs, wavelengthsListToCompute, ...
            targetPupilDiamMM, targetPupilDiamMM, umPerDegree, '');
    
    xSfCyclesPerRetinalMicron = wvfGet(theWVF, 'otf support', 'um', wavelengthsListToCompute(1));
    xSfCyclesDeg = xSfCyclesPerRetinalMicron * wvfGet(theWVF,'um per degree');
    ySfCyclesDeg = xSfCyclesDeg;
    [xSfGridCyclesDegGrid,ySfGridCyclesDegGrid] = meshgrid(xSfCyclesDeg, ySfCyclesDeg);
    
    if (~isempty(centeringWavelength))
        % Retrieve OTF at the centeringWavelength
        theCenteringOTF = wvfGet(theWVF, 'otf', centeringWavelength);
        theCenteringPSF = wvfGet(theWVF, 'psf', centeringWavelength);
        translationVector = []; showTranslation = false;
        [~, translationVector, ~, ~, ~] = otfWithZeroCenteredPSF(...
                    theCenteringOTF, theCenteringPSF, ...
                    translationVector, xSfGridCyclesDegGrid,ySfGridCyclesDegGrid, ...
                    showTranslation);
    else
        translationVector = [0 0];
    end
    
    for wIndex = 1:numel(wavelengthsListToCompute)
        theWaveOTF = wvfGet(theWVF, 'otf', wavelengthsListToCompute(wIndex));
        theWavePSF = wvfGet(theWVF, 'psf', wavelengthsListToCompute(wIndex));
        showTranslation = false;
        [theWaveOTF, ~, ~, ~,~] = ...
            otfWithZeroCenteredPSF(theWaveOTF, theWavePSF, translationVector,  xSfGridCyclesDegGrid, ySfGridCyclesDegGrid, showTranslation);
        
        [xGridMinutes,yGridMinutes, theWavePSF] = ...
            OtfToPsf(xSfGridCyclesDegGrid,ySfGridCyclesDegGrid,fftshift(theWaveOTF));
        if (wIndex == 1)
            OTFs = zeros(size(theWaveOTF,1), size(theWaveOTF,2), numel(wavelengthsListToCompute));
            PSFs = zeros(size(theWavePSF,1), size(theWavePSF,2), numel(wavelengthsListToCompute));
        end
        
        OTFs(:,:,wIndex) = fftshift(theWaveOTF);
        PSFs(:,:,wIndex) = theWavePSF;
    end
    
    xMinutes = xGridMinutes(1,:);
    yMinutes = yGridMinutes(:,1);
end

function theWVF = makeWVF(wavefrontSpatialSamples, zcoeffs, wavelengthsToCompute, measPupilDiameterMM, calcPupilDiameterMM, umPerDegree, name)
    theWVF = wvfCreate(...
    			'umPerDegree', umPerDegree, ...
                'calc wavelengths',wavelengthsToCompute,...
                'measuredpupil', measPupilDiameterMM, ...
                'calc pupil size',calcPupilDiameterMM, ...
                'spatialsamples', wavefrontSpatialSamples, ...
                'zcoeffs', zcoeffs,...
                'name', name);
    
    % Now compute the PSF
    theWVF = wvfComputePSF(theWVF);
end

function [centeredOTF,  translationVector, centeredPSF, xGridMinutes,yGridMinutes] = otfWithZeroCenteredPSF(OTF, PSF, translationVector,  xSfGridCyclesDegGrid, ySfGridCyclesDegGrid, showTranslation)
    if (isempty(translationVector))
        % Compute center of mass
        %centerOfMass = computeCenterOfMass(PSF);
        centerOfMass = computeCenterOfMassNative(PSF);
        centerPosition = floor(size(PSF,1)/2) + 1 * [1 1];
        
        if (showTranslation)
            figure(200);clf
            imagesc(1:size(PSF,2), 1:size(PSF,1), PSF);
            hold on;
            plot(centerPosition(1)*[1 1], [1 size(PSF,1)], 'k-');
            plot([1 size(PSF,2)], centerPosition(2)*[1 1], 'k-');
            plot(centerOfMass(1), centerOfMass(2), 'ro', 'MarkerFaceColor', [1 0.5 0.5]);
            plot([centerPosition(1) centerOfMass(1)], [centerPosition(2)  centerOfMass(2)], 'r-');
            hold off;
            axis 'square'
            colormap(gray(1024));
            drawnow;
        end
        
        % Compute translation vector to bring center of mass at 0,0
        translationVector = (centerPosition-centerOfMass);
    end
    centeredOTF = shiftInFTplane(OTF, translationVector);

    [xGridMinutes,yGridMinutes,centeredPSF] = OtfToPsf(xSfGridCyclesDegGrid,ySfGridCyclesDegGrid,fftshift(centeredOTF));
    
    if (abs(sum(centeredPSF(:))-1) > 1000*eps(1))
        fprintf('centeredPSF min = %1.9f, max = %1.9f, sum = %1.9f\n', min(centeredPSF(:)), max(centeredPSF(:)), sum(centeredPSF(:)));
        error('PSF volume does not equal 1\n');
    end
   
end

function centerOfMass = computeCenterOfMassNative(PSF)
    [rc,cc] = ndgrid(1:size(PSF,1),1:size(PSF,2));
    Mt = sum(PSF(:));
    centerOfMassY = sum(PSF(:) .* rc(:)) / Mt;
    centerOfMassX = sum(PSF(:) .* cc(:)) / Mt;
    centerOfMass1 = [centerOfMassX centerOfMassY];
    [~,idx] = max(PSF(:));
    [i,j] = ind2sub(size(PSF), idx);
    centerOfMass = [j i];
end

function otf = shiftInFTplane(otf, translationVector)
    [N, M] = size(otf);
    x = [0:floor(N/2) floor(-N/2)+1:-1];
    y = [0:floor(M/2) floor(-M/2)+1:-1];
    x_shift = exp(-1i * 2 * pi * translationVector(2) * x' / N);
    y_shift = exp(-1i * 2 * pi * translationVector(1) * y / M);

    % Force conjugate symmetry. Otherwise this frequency component has no
    % corresponding negative frequency to cancel out its imaginary part.
    if mod(N, 2) == 0
        x_shift(N/2+1) = real(x_shift(N/2+1));
    end 
    if mod(M, 2) == 0
        y_shift(M/2+1) = real(y_shift(M/2+1));
    end
    maxOTF = max(otf(:));
    otf = otf .* (x_shift * y_shift);
    otf = otf / max(abs(otf(:))) * maxOTF;
end
