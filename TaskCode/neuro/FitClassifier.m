function C = FitClassifier(Params,datadir,dimRedFunc)
% function C = FitClassifier(Params,datadir,dimRedFunc)
% Uses all trials in given data directory to initialize classifier
% filter. Returns classifier object 
% 
% datadir - directory containing trials to fit data on
% C -classifier object
% dimRedFunc - function handle for dimensionality red. redX = dimRedFunc(X)

% ouput to screen
fprintf('\n\nFitting Classifer:\n')
fprintf('  Data in %s\n', datadir)

% always use gui to override datadir
datadir = uigetdir(datadir);

% grab data trial data
datafiles = dir(fullfile(datadir,'Data*.mat'));
X = [];
Y = [];
for i=1:length(datafiles),
    % load data, grab neural data + target
    load(fullfile(datadir,datafiles(i).name)) %#ok<LOAD>
    % ignore inter-trial interval data
    if strcmp(TrialData.Events(1).Str, 'Inter Trial Interval'),
        tidx = (TrialData.Time >= TrialData.Events(2).Time) ...
            & (TrialData.Time <= TrialData.Events(3).Time);
    else,
        tidx = (TrialData.Time >= TrialData.Events(1).Time) ...
            & (TrialData.Time <= TrialData.Events(2).Time);
    end
    Xtrial = cat(2,TrialData.NeuralFeatures{:,tidx});
    % if DimRed is on, reduce dimensionality of neural features
    if exist('dimRedFunc','var'),
        Xtrial = dimRedFunc(Xtrial);
    end
    X = cat(1,X,mean(Xtrial,2)');
    Y = cat(1,Y,TrialData.TargetID);
end

% fit classifier
switch Params.ClassifierType,
    case 1, C = fitcdiscr(X,Y,'DiscrimType','linear','Prior','uniform');
    case 2, C = fitcdiscr(X,Y,'DiscrimType','quadratic','Prior','uniform');
end

end % FitClassifier
