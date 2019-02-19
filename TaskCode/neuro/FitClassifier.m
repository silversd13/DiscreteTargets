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

% neural features idx
if Params.InterTrialInterval>0,
    idx = 2;
else,
    idx = 1;
end

% grab data trial data
datafiles = dir(fullfile(datadir,'Data*.mat'));
X = [];
Y = [];
for i=1:length(datafiles),
    % load data, grab neural data + target
    load(fullfile(datadir,datafiles(i).name)) %#ok<LOAD>
    Xtrial = cat(2,TrialData.NeuralFeatures{idx,:});
    % if DimRed is on, reduce dimensionality of neural features
    if exist('dimRedFunc','var'),
        Xtrial = dimRedFunc(Xtrial);
    end
    X = cat(1,X,Xtrial(:)');
    Y = cat(1,Y,TrialData.TargetID);
end

% fit classifier
switch Params.ClassifierType,
    case 1, C = fitcdiscr(X,Y,'DiscrimType','linear');
    case 2, C = fitcdiscr(X,Y,'DiscrimType','quadratic');
end

end % FitClassifier
