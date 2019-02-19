function [Data, Neuro] = RunTrial(Data,Params,Neuro,TaskFlag)
% Runs a trial, saves useful data along the way
% Each trial contains the following pieces
% 1) Inter-trial interval
% 2) Get the cursor to the start target (center)
% 3) Hold position during an instructed delay period
% 4) Get the cursor to the reach target (different on each trial)
% 5) Feedback

global Cursor

%% Set up trial
ReachTargetPos = Data.TargetPosition;
LastPredictTime = GetSecs;

% Output to Command Line
fprintf('\nTrial: %i\n',Data.Trial)
fprintf('Target: %i\n',Data.TargetPosition)
if Params.Verbose,
    fprintf('  Cursor Assistance: %.2f\n',Cursor.Assistance)
    if Params.CLDA.Type==3,
        fprintf('  Lambda: %.5g\n',Neuro.CLDA.Lambda)
    end
end

% keep track of update times
dt_vec = [];
dT_vec = [];

%% Inter Trial Interval
if ~Data.ErrorID && Params.InterTrialInterval>0,
    tstart  = GetSecs;
    Data.Events(end+1).Time = tstart;
    Data.Events(end).Str  = 'Inter Trial Interval';
    
    done = 0;
    TotalTime = 0;
    while ~done,
        % Update Time & Position
        tim = GetSecs;

        % for pausing and quitting expt
        if CheckPause, [Neuro,Data] = ExperimentPause(Params,Neuro,Data); end

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
                elseif Params.GenNeuralFeaturesFlag,
                    Neuro.NeuralFeatures = VelToNeuralFeatures(Params);
                    if Neuro.DimRed.Flag,
                        Neuro.NeuralFactors = Neuro.DimRed.F(Neuro.NeuralFeatures);
                        Data.NeuralFactors{end+1} = Neuro.NeuralFactors;
                    end
                    Data.NeuralFeatures{end+1} = Neuro.NeuralFeatures;
                    Data.NeuralTime(1,end+1) = tim;
                end
            end
            
            % draw
            Screen('FillOval', Params.WPTR, Params.CursorColor, CursorRect);
            Screen('DrawingFinished', Params.WPTR);
            Screen('Flip', Params.WPTR);
        end

        % end if takes too long
        if TotalTime > Params.InterTrialInterval,
            done = 1;
        end

    end % Inter Trial Interval
end % only complete if no errors

%% Target Selection
if ~Data.ErrorID,
    tstart  = GetSecs;
    Data.Events(end+1).Time = tstart;
    Data.Events(end).Str  = 'Target Selection Interval';

    done = 0;
    TotalTime = 0;
    while ~done,
        % Update Time & Position
        tim = GetSecs;

        % for pausing and quitting expt
        if CheckPause, [Neuro,Data] = ExperimentPause(Params,Neuro,Data); end

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
                elseif Params.GenNeuralFeaturesFlag,
                    Neuro.NeuralFeatures = VelToNeuralFeatures(Params);
                    if Neuro.DimRed.Flag,
                        Neuro.NeuralFactors = Neuro.DimRed.F(Neuro.NeuralFeatures);
                        Data.NeuralFactors{end+1} = Neuro.NeuralFactors;
                    end
                    Data.NeuralFeatures{end+1} = Neuro.NeuralFeatures;
                    Data.NeuralTime(1,end+1) = tim;
                end
                KF = UpdateCursor(Params,Neuro,TaskFlag,ReachTargetPos,KF);
            end
            
            % reach target
            ReachRect = Params.TargetRect; % centered at (0,0)
            ReachRect([1,3]) = ReachRect([1,3]) + ReachTargetPos(1) + Params.Center(1); % add x-pos
            ReachRect([2,4]) = ReachRect([2,4]) + ReachTargetPos(2) + Params.Center(2); % add y-pos

            % draw
            Screen('FillOval', Params.WPTR, ...
                cat(1,ReachCol,Params.CursorColor)', ...
                cat(1,ReachRect,CursorRect)')
            Screen('DrawingFinished', Params.WPTR);
            Screen('Flip', Params.WPTR);
            
        end

        % end if takes too long
        if TotalTime > Params.SelectionTime,
            done = 1;
            fprintf('\nERROR: %s\n',Data.ErrorStr)
        end

    end % Reach Target Loop
end % only complete if no errors


%% Completed Trial - Give Feedback
Screen('Flip', Params.WPTR);

% output update times
if Params.Verbose,
    fprintf('Screen Update Frequency: Goal=%iHz, Actual=%.2fHz (+/-%.2fHz)\n',...
        Params.ScreenRefreshRate,mean(1./dt_vec),std(1./dt_vec))
    fprintf('System Update Frequency: Goal=%iHz, Actual=%.2fHz (+/-%.2fHz)\n',...
        Params.UpdateRate,mean(1./dT_vec),std(1./dT_vec))
end

% output feedback
if Data.ErrorID==0,
    fprintf('\nSUCCESS\n')
    if Params.FeedbackSound,
        sound(Params.RewardSound,Params.RewardSoundFs)
    end
else
    if Params.FeedbackSound,
        sound(Params.ErrorSound,Params.ErrorSoundFs)
    end
    WaitSecs(Params.ErrorWaitTime);
end

end % RunTrial



