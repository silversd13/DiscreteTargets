function [Neuro,Params] = RunLoop(Params,Neuro,TaskFlag,DataDir,TargetClassifier)
% Defines the structure of collected data on each trial
% Loops through blocks and trials within blocks

%% Start Experiment
DataFields = struct(...
    'Block',NaN,...
    'Trial',NaN,...
    'TrialStartTime',NaN,...
    'TrialEndTime',NaN,...
    'TargetID',NaN,...
    'TargetPosition',NaN,...
    'SelectedTargetID',NaN,...
    'Time',[],...
    'NeuralTime',{{}},...
    'NeuralTimeBR',[],...
    'NeuralSamps',[],...
    'NeuralFeatures',{{}},...
    'NeuralFactors',{{}},...
    'BroadbandData',{{}},...
    'ProcessedData',{{}},...
    'ErrorID',NaN,...
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
Neuro.LastUpdateTime = tlast;
for Block=1:NumBlocks, % Block Loop

    % random order of reach targets for each block
    TargetOrder = Params.TargetFunc(Params.NumTrialsPerBlock);

    for TrialPerBlock=1:Params.NumTrialsPerBlock, % Trial Loop
        % update trial
        Trial = Trial + 1;
        TrialIdx = TargetOrder(TrialPerBlock);
        
        % set up trial
        TrialData = DataFields;
        TrialData.Block = Block;
        TrialData.Trial = Trial;
        TrialData.TargetID = TrialIdx;
        TrialData.TargetPosition = Params.TargetPositions(TrialIdx,:);

        % Run Trial
        TrialData.TrialStartTime  = GetSecs;
        [TrialData,Neuro,Params] = RunTrial(TrialData,Params,Neuro,TaskFlag,TargetClassifier);
        TrialData.TrialEndTime    = GetSecs;
                
        % Save Data from Single Trial
        save(...
            fullfile(DataDir,sprintf('Data%04i.mat',Trial)),...
            'TrialData',...
            '-v7.3','-nocompression');
        
    end % Trial Loop
    
    % Give Feedback for Block
    if Params.InterBlockInterval >= 10,
        Instructions = [...
            sprintf('\n\nFinished block %i of %i\n\n',Block,NumBlocks),...
            '\nPress the ''Space Bar'' to resume task.' ];
        InstructionScreen(Params,Instructions)
    else,
        WaitSecs(Params.InterBlockInterval);
    end
    
end % Block Loop

end % RunLoop



