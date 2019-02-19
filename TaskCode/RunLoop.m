function [Neuro,KF] = RunLoop(Params,Neuro,TaskFlag,DataDir,KF)
% Defines the structure of collected data on each trial
% Loops through blocks and trials within blocks

global Cursor

%% Start Experiment
DataFields = struct(...
    'Block',NaN,...
    'Trial',NaN,...
    'TrialStartTime',NaN,...
    'TrialEndTime',NaN,...
    'TargetPosition',NaN,...
    'Time',[],...
    'NeuralTime',[],...
    'NeuralTimeBR',[],...
    'NeuralSamps',[],...
    'NeuralFeatures',{{}},...
    'NeuralFactors',{{}},...
    'ProcessedData',{{}},...
    'ErrorID',0,...
    'ErrorStr','',...
    'Events',[]...
    );

switch TaskFlag,
    case 1, NumBlocks = Params.NumImaginedBlocks;
    case 2, NumBlocks = Params.NumFixedBlocks;
end

%%  Loop Through Blocks of Trials
Trial = 0;
tlast = GetSecs;
LastPredictTime = tlast;
Neuro.LastUpdateTime = tlast;
for Block=1:NumBlocks, % Block Loop

    for TrialPerBlock=1:Params.NumTrialsPerBlock, % Trial Loop
        % update trial
        Trial = Trial + 1;
        
        % set up trial
        TrialData = DataFields;
        TrialData.Block = Block;
        TrialData.Trial = Trial;
        TrialData.TargetPosition = Params.TargetFunc();
        TrialData.KalmanFilter = KF;

        % Run Trial
        TrialData.TrialStartTime  = GetSecs;
        [TrialData,Neuro] = RunTrial(TrialData,Params,Neuro,TaskFlag);
        TrialData.TrialEndTime    = GetSecs;
                
        % Save Data from Single Trial
        save(...
            fullfile(DataDir,sprintf('Data%04i.mat',Trial)),...
            'TrialData',...
            '-v7.3','-nocompression');
        
    end % Trial Loop
    
    % Give Feedback for Block
    WaitSecs(Params.InterBlockInterval);
    
end % Block Loop

end % RunLoop



