function [Data, Neuro, Params] = RunTrial(Data,Params,Neuro,TaskFlag,TargetClassifier)
% Runs a trial, saves useful data along the way
% Each trial contains the following pieces
% 1) Inter-trial interval
% 2) Get the cursor to the start target (center)
% 3) Hold position during an instructed delay period
% 4) Get the cursor to the reach target (different on each trial)
% 5) Feedback

%% Set up trial
OnTargetPos = Data.TargetPosition;
OffTargetPos = Params.TargetPositions(setdiff(1:Params.NumTargets,Data.TargetID),:)';

% targets
OnTargetRect = Params.TargetRect(:); % centered at (0,0)
OnTargetRect([1,3]) = OnTargetRect([1,3]) + OnTargetPos(1) + Params.Center(1); % add x-pos
OnTargetRect([2,4]) = OnTargetRect([2,4]) + OnTargetPos(2) + Params.Center(2); % add y-pos

OffTargetRect = repmat(Params.TargetRect(:),1,Params.NumTargets-1); % centered at (0,0)
OffTargetRect([1,3],:) = OffTargetRect([1,3],:) + OffTargetPos(1,:) + Params.Center(1); % add x-pos
OffTargetRect([2,4],:) = OffTargetRect([2,4],:) + OffTargetPos(2,:) + Params.Center(2); % add y-pos

TargetRect = cat(2,OffTargetRect(:,1:Data.TargetID-1),...
    OnTargetRect,...
    OffTargetRect(:,Data.TargetID:end));
TargetCol = cat(1,repmat(Params.OffCol,Params.NumTargets,1))';
TargetCol(:,Data.TargetID) = Params.OnCol;

% Output to Command Line
fprintf('\nTrial: %i\n',Data.Trial)
fprintf('Target: (%i, { %i , %i })\n',...
    Data.TargetID,...
    Data.TargetPosition(1),...
    Data.TargetPosition(2))

% keep track of update times
dt_vec = [];
dT_vec = [];
LastPredictTime = GetSecs;

%% Inter Trial Interval
if Params.InterTrialInterval>0,
    tstart  = GetSecs;
    Data.Events(end+1).Time = tstart;
    Data.Events(end).Str  = 'Inter Trial Interval';
    NumEvents = length(Data.Events);
    
    % draw
    Screen('Flip', Params.WPTR);
    
    done = 0;
    TotalTime = 0;
    while ~done,
        % Update Time & Position
        tim = GetSecs;

        % for pausing and quitting expt
        if CheckPause, [Neuro,Data,Params] = ExperimentPause(Params,Neuro,Data); end

        % Update Screen Every Xsec
        if (tim-LastPredictTime) > 1/Params.ScreenRefreshRate,
            % time
            dt = tim - LastPredictTime;
            TotalTime = TotalTime + dt;
            dt_vec(end+1) = dt; %#ok<*AGROW>
            LastPredictTime = tim;
            Data.Time(1,end+1) = tim;
            
            % grab and process neural data
            if ((tim-Neuro.LastUpdateTime)>1/Params.UpdateRate),
                dT = tim-Neuro.LastUpdateTime;
                dT_vec(end+1) = dT;
                Neuro.LastUpdateTime = tim;
                if Params.BLACKROCK,
                    [Neuro,Data] = NeuroPipeline(Neuro,Data);
                    Data.NeuralTime(1,end+1) = tim;
                end
                if Params.GenNeuralFeaturesFlag,
                    Neuro.NeuralFeatures = VelToNeuralFeatures(Params);
                    if Params.BLACKROCK, % override
                        Data.NeuralFeatures{end} = Neuro.NeuralFeatures;
                    else,
                        Data.NeuralFeatures{end+1} = Neuro.NeuralFeatures;
                    end
                end
                if Neuro.DimRed.Flag,
                    Neuro.NeuralFactors = Neuro.DimRed.F(Neuro.NeuralFeatures);
                    Data.NeuralFactors{end+1} = Neuro.NeuralFactors;
                end
            end
            
        end

        % end if takes too long
        if TotalTime > Params.InterTrialInterval,
            done = 1;
        end

    end % Inter Trial Interval
end % only complete if no errors

%% Target Selection
tstart  = GetSecs;
Data.Events(end+1).Time = tstart;
Data.Events(end).Str  = 'Target Selection Interval';
NumEvents = length(Data.Events);

% draw
Screen('FillOval', Params.WPTR, TargetCol, TargetRect);
Screen('Flip', Params.WPTR);

done = 0;
TotalTime = 0;
while ~done,
    % Update Time & Position
    tim = GetSecs;
    
    % for pausing and quitting expt
    if CheckPause, [Neuro,Data,Params] = ExperimentPause(Params,Neuro,Data); end
    
    % Update Screen
    if (tim-LastPredictTime) > 1/Params.ScreenRefreshRate,
        % time
        dt = tim - LastPredictTime;
        TotalTime = TotalTime + dt;
        dt_vec(end+1) = dt;
        LastPredictTime = tim;
        Data.Time(1,end+1) = tim;
        
        % grab and process neural data
        if ((tim-Neuro.LastUpdateTime)>1/Params.UpdateRate),
            dT = tim-Neuro.LastUpdateTime;
            dT_vec(end+1) = dT;
            Neuro.LastUpdateTime = tim;
            if Params.BLACKROCK,
                [Neuro,Data] = NeuroPipeline(Neuro,Data);
                Data.NeuralTime(1,end+1) = tim;
            end
            if Params.GenNeuralFeaturesFlag,
                Neuro.NeuralFeatures = VelToNeuralFeatures(Params);
                if Params.BLACKROCK, % override
                    Data.NeuralFeatures{end} = Neuro.NeuralFeatures;
                else,
                    Data.NeuralFeatures{end+1} = Neuro.NeuralFeatures;
                end
            end
            if Neuro.DimRed.Flag,
                Neuro.NeuralFactors = Neuro.DimRed.F(Neuro.NeuralFeatures);
                Data.NeuralFactors{end+1} = Neuro.NeuralFactors;
            end
        end
        
    end
    
    % end if takes too long
    if TotalTime > Params.SelectionInterval,
        done = 1;
    end
    
end % Target Selection Loop

%% Target Selected Feedback (Blink Selected Target)
switch TaskFlag,
    case 1, % Imagined (select on target)
        Data.SelectedTargetID = Data.TargetID;
    case 2, % Fixed (decode on target)
        if ~exist('TargetClassifier','var'),
            error('No classifier given'); 
        else,
            if Neuro.DimRed.Flag,
                X = cat(2,Data.NeuralFactors{NumEvents,:});
                X = X(:)';
            else,
                X = cat(2,Data.NeuralFeatures{NumEvents,:});
                X = X(:)';
            end
            Data.SelectedTargetID = predict(TargetClassifier,X);
        end
end
TargetColBlink = TargetCol;
TargetColBlink(:,Data.SelectedTargetID) = Params.SelCol;

tstart  = GetSecs;
Data.Events(end+1).Time = tstart;
Data.Events(end).Str  = 'Feedback Interval';
NumEvents = length(Data.Events);

% correct or not?
if Data.SelectedTargetID==Data.TargetID,
    Data.ErrorID = 0;
    Data.ErrorStr = 'none';
else,
    Data.ErrorID = 1;
    Data.ErrorStr = 'wrong target';
end

% sound feedback
if Data.ErrorID==0,
    fprintf('\nSUCCESS\n')
    if Params.FeedbackSound,
        sound(Params.RewardSound,Params.RewardSoundFs)
    end
else
    if Params.FeedbackSound,
        sound(Params.ErrorSound,Params.ErrorSoundFs)
    end
end

done = 0;
TotalTime = 0;
ct = 0;
while ~done,
    % Update Time & Position
    tim = GetSecs;
    
    % for pausing and quitting expt
    if CheckPause, [Neuro,Data,Params] = ExperimentPause(Params,Neuro,Data); end
    
    % Update Screen
    if (tim-LastPredictTime) > 1/Params.ScreenRefreshRate,
        % time
        dt = tim - LastPredictTime;
        TotalTime = TotalTime + dt;
        dt_vec(end+1) = dt;
        LastPredictTime = tim;
        Data.Time(1,end+1) = tim;
        
        % grab and process neural data
        if ((tim-Neuro.LastUpdateTime)>1/Params.UpdateRate),
            dT = tim-Neuro.LastUpdateTime;
            dT_vec(end+1) = dT;
            Neuro.LastUpdateTime = tim;
            if Params.BLACKROCK,
                [Neuro,Data] = NeuroPipeline(Neuro,Data);
                Data.NeuralTime(1,end+1) = tim;
            end
            if Params.GenNeuralFeaturesFlag,
                Neuro.NeuralFeatures = VelToNeuralFeatures(Params);
                if Params.BLACKROCK, % override
                    Data.NeuralFeatures{end} = Neuro.NeuralFeatures;
                else,
                    Data.NeuralFeatures{end+1} = Neuro.NeuralFeatures;
                end
            end
            if Neuro.DimRed.Flag,
                Neuro.NeuralFactors = Neuro.DimRed.F(Neuro.NeuralFeatures);
                Data.NeuralFactors{end+1} = Neuro.NeuralFactors;
            end
        end
        
        % draw blinking target
        if mod(ct,3)==0,
            Screen('FillOval', Params.WPTR, TargetCol, TargetRect);
        else,
            Screen('FillOval', Params.WPTR, TargetColBlink, TargetRect);
        end
        ct = ct + 1;
        Screen('Flip', Params.WPTR);
    end
    
    % end if takes too long
    if TotalTime > Params.FeedbackInterval,
        done = 1;
    end
    
end % Target Selected Feedback Loop

%% Completed Trial - Give Feedback
Screen('Flip', Params.WPTR);

% output update times
if Params.Verbose,
    fprintf('Screen Update Frequency: Goal=%iHz, Actual=%.2fHz (+/-%.2fHz)\n',...
        Params.ScreenRefreshRate,mean(1./dt_vec),std(1./dt_vec))
    fprintf('System Update Frequency: Goal=%iHz, Actual=%.2fHz (+/-%.2fHz)\n',...
        Params.UpdateRate,mean(1./dT_vec),std(1./dT_vec))
end

end % RunTrial



