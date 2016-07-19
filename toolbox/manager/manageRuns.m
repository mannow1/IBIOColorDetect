function manageRuns

    targetDir = '/Users/Shared/Matlab/Analysis/IBIOColorDetect';
    targetDir = '/Users/Shared/Matlab/Analysis/IBIOColorDetect/toolbox/manager/DummyData';
    
    dataFormat.level1 = {...
        {'cpd',  'numeric'} ...
        {'_sfv', 'numeric'} ...
        {'_fw',  'numeric'} ...
        {'_tau', 'numeric'} ...
        {'_dur', 'numeric'} ...
        {'_nem', 'numeric'} ...
        {'_use', 'numeric'} ...
        {'_off', 'numeric'} ...
        {'_b',   'numeric'} ...
        {'_l',   'numeric'} ...
        {'_LMS', 'char'} ...
        {'_mfv', 'numeric'} ...
    };
   
    dataFormat.level2 = {...
        {'signalsource',  'char'} ...
        {'intervals', 'char'} ...
        {'svmvalidation', 'char'} ...
        {'pcacomp', 'char'} ...
    };

    startGUI(targetDir, dataFormat);
end


