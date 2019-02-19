function Neuro = RunTask(Params,Neuro,TaskFlag)
% Explains the task to the subject, and serves as a reminder for pausing
% and quitting the experiment (w/o killing matlab or something)

switch TaskFlag,
    case 1, % Imagined Movements
        Instructions = [...
            '\n\nImagined Selection\n\n'...
            'Imagine moving a mouse into the green target.\n'...
            '\nAt any time, you can press ''p'' to briefly pause the task.'...
            '\n\nPress the ''Space Bar'' to begin!' ];
        
        InstructionScreen(Params,Instructions);
        mkdir(fullfile(Params.Datadir,'Imagined'));
        
        % output to screen
        fprintf('\n\nImagined Selections:\n')
        fprintf('  %i Blocks (%i Total Trials)\n',...
            Params.NumImaginedBlocks,...
            Params.NumImaginedBlocks*Params.NumTrialsPerBlock)
        fprintf('  Saving data to %s\n\n',fullfile(Params.Datadir,'Imagined'))
        
        Neuro.DimRed.Flag = false; % set to false for imagined mvmts
        Neuro = RunLoop(Params,Neuro,TaskFlag,fullfile(Params.Datadir,'Imagined'));
        
    case 2, % Fixed Decoder
        Instructions = [...
            '\n\nImagined Selection\n\n'...
            'Imagine moving a mouse into the green target.\n'...
            '\nAt any time, you can press ''p'' to briefly pause the task.'...
            '\n\nPress the ''Space Bar'' to begin!' ];
        
        InstructionScreen(Params,Instructions);
        mkdir(fullfile(Params.Datadir,'BCI_Fixed'));
        
            
        Neuro.DimRed.Flag = Params.DimRed.Flag; % reset for task
        % fit decoder
        
        % output to screen
        fprintf('\n\nFixed Selections:\n')
        fprintf('  %i Blocks (%i Total Trials)\n',...
            Params.NumFixedBlocks,...
            Params.NumFixedBlocks*Params.NumTrialsPerBlock)
        fprintf('  Saving data to %s\n\n',fullfile(Params.Datadir,'BCI_Fixed'))
        
        Neuro = RunLoop(Params,Neuro,TaskFlag,fullfile(Params.Datadir,'BCI_Fixed'));
        
end

end % RunTask
