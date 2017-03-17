function visualizeTransformedSignals(timeAxis, noStimResponses, stimResponses, signalSource, stimContrast, spatialFilterName)

    hFig = figure(1234); clf;
    set(hFig, 'Position', [10 10 400 800]);

    responseRange = [...
            min([min(stimResponses(:)) min(noStimResponses(:))]) ...
            max([max(stimResponses(:)) max(noStimResponses(:))])
        ];
    
    subplot(2,1,1);
    plot(timeAxis, noStimResponses, 'k-')
    set(gca, 'YLim', responseRange,  'XLim', [timeAxis(1) timeAxis(end)]);
    title(sprintf('NO-STIM\n%s-based filter response', signalSource));
    ylabel(sprintf('%s output', spatialFilterName));
    set(gca, 'FontSize', 14);

    subplot(2,1,2);
    plot(timeAxis, stimResponses, 'k-')
    set(gca, 'YLim', responseRange,  'XLim', [timeAxis(1) timeAxis(end)]);
    title(sprintf('C = %2.5f%%\n%s-based filter response', stimContrast, signalSource));
    ylabel(sprintf('%s output', spatialFilterName));
    set(gca, 'FontSize', 14);
    xlabel('time (ms)'); 
    
    drawnow;
    NicePlot.exportFigToPDF('transformedSignals.pdf', hFig, 300); 
end

