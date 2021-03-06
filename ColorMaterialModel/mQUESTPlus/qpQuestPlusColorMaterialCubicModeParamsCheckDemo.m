% Demonstrate/test QUEST+ at work on the color material model, cubic
%
% Description:
%    This script shows QUEST+ employed to estimate the parameters of the
%    cubic version of the color material model.
%
%    To keep things managable in terms of time, the sampling of the
%    parameter space is sparse.  Not sure how that trades off in terms
%    of quality of stimulus choices.

% 12/19/17  dhb, ar  Created.
% 01/05/18  dhb      Futz with bounds on parameters so it doesn't bomb.
% 01/24/18  dhb      Cubic version.

%% Close out stray figures
clear; close all;

%% Change to our pwd
cd(fileparts(mfilename('fullpath')));

%% We need the lookup table.  Load it.
%theLookupTable = load('../colorMaterialInterpolateFunLineareuclidean');
theLookupTable = load('../colorMaterialInterpolateFunCubiceuclidean');

%% Define psychometric function in terms of lookup table
qpPFFun = @(stimParams,psiParams) qpPFColorMaterialCubicModel(stimParams,psiParams,theLookupTable.colorMaterialInterpolatorFunction);

%% Define parameters that set up parameter grid for QUEST+
lowerLin = 0.5;
upperLin = 6;
lowerQuad = -0.3;
upperQuad = -lowerQuad;
lowerCubic = -0.3;
upperCubic = -lowerCubic;
lowerWeight = 0.05;
upperWeight = 0.95;
nLin = 5;
nQuad = 4;
nCubic = 4;
nWeight = 5;

% Set up parameter constraints.  Might do more beautifully someday
maxStimValue = 3;
maxPosition = 20;
minSpacing = 0.25;

% Does a simple simulation as in the experiment. 
ALSO_SIMULATE = false;

%% Initialize three QUEST+ structures
%
% Each one has a different upper end of stimulus regime
% The last of these should be the most inclusive, and
% include stimuli that could come from any of them.
DO_INITIALIZE = false;
if (DO_INITIALIZE)
    stimUpperEnds = [1 2 3];
    nQuests = length(stimUpperEnds);
    for qq = 1:nQuests
        fprintf('Initializing quest structure %d\n',qq)
        questData{qq} = qpInitialize( ...
            'qpPF',qpPFFun, ...
            'stimParamsDomainList',{-stimUpperEnds(qq):stimUpperEnds(qq), -stimUpperEnds(qq):stimUpperEnds(qq), -stimUpperEnds(qq):stimUpperEnds(qq), -stimUpperEnds(qq):stimUpperEnds(qq)}, ...
            'psiParamsDomainList',{ linspace(lowerLin,upperLin,nLin) linspace(lowerQuad,upperQuad,nQuad) linspace(lowerCubic,upperCubic,nCubic) ...
                                    linspace(lowerLin,upperLin,nLin) linspace(lowerQuad,upperQuad,nQuad) linspace(lowerCubic,upperCubic,nCubic) ...
                                    linspace(lowerWeight,upperWeight,nWeight) }, ...
            'filterPsiParamsDomainFun',@(psiParams) qpQuestPlusColorMaterialCubicModelParamsCheck(psiParams,maxStimValue,maxPosition,minSpacing) ...
            );
    end
    
    %% Define a questStructure that has all the stimuli
    %
    % We use this as a simple way to account for every
    % stimulus in the analysis at the end.
    questDataAllTrials = questData{end};
    
    %% Save out initialized quests
    save(fullfile(tempdir,'initalizedQuestsParamsCheck'),'questData','questDataAllTrials');
end

% Load in intialized questDataAllTrials.  We do this outside
% the big loop over simulated sessions, as it is common acorss 
% those simulated sessions.
clear questDataAllTrials
load(fullfile(tempdir,'initalizedQuestsParamsCheck'),'questDataAllTrials');

%% Set up simulated observer function
simulatedPsiParams = [3 0 0 2 0 0 0.2];
simulatedObserverFun = @(x) qpSimulatedObserver(x,qpPFFun,simulatedPsiParams);

%% Run multiple simulations
nSessions = 1;
nTrialsPerQuest = 30;
questOrderIn = [0 1 2 3 3 3 3 3 3];
for ss = 1:nSessions
    % Load in the initialized quest structures
    fprintf('Session %d of %d\n',ss,nSessions);

    % Load just the initialized questData structures, leaving
    % the questDataAllTrials structure intact.  We do this separately
    % for each simulated session.
    clear questData
    load(fullfile(tempdir,'initalizedQuestsParamsCheck'),'questData');
    
    % Force questDataAllTrials not to update entropy. This speeds things up
    % quite a bit, although you can't then make a nice plot of entropy as a
    % function of trial.
    questDataAllTrials.noentropy = true;
    questDataAllTrials1 = questDataAllTrials;
    
    % Run simulated trials, using QUEST+ to tell us what contrast to
    %
    % Define how many of each type of trial selection we'll do each time through.
    % 0 -> choose at random from all trials.
    for tt = 1:nTrialsPerQuest
        fprintf('\tTrial block %d of %d\n',tt,nTrialsPerQuest');
        bstart = tic;
        
        % Set the order for the specified quests and random
        questOrder = randperm(length(questOrderIn));
        for qq = 1:length(questOrder)
            theQuest = questOrderIn(questOrder(qq));
            
            % Get stimulus for this trial, either from one of the quests or at random.
            if (theQuest > 0)
                stim = qpQuery(questData{theQuest});
            else
                nStimuli = size(questDataAllTrials.stimParamsDomain,1);
                stim = questDataAllTrials.stimParamsDomain(randi(nStimuli),:);
            end
            
            % Simulate outcome
            if (ALSO_SIMULATE)
                targetC = normrnd(0,1);
                targetM = normrnd(0,1);
                weight = 0.2;
                d1 = sqrt( (weight*(3*stim(1) + normrnd(0,1) - targetC))^2 + ((1-weight)*(2*stim(3) + normrnd(0,1) - targetM))^2 );
                d2 = sqrt( (weight*(3*stim(2) + normrnd(0,1) - targetC))^2 + ((1-weight)*(2*stim(4) + normrnd(0,1) - targetM))^2 );
                if (d1 < d2) 
                    outcome1 =1;
                else
                    outcome1 = 2;
                end
                questDataAllTrials1 = qpUpdate(questDataAllTrials1,stim,outcome1);
            end
            outcome = simulatedObserverFun(stim);
            
            % Update quest data structure, if not a randomly inserted trial
            %tic
            if (theQuest > 0)
                questData{theQuest} = qpUpdate(questData{theQuest},stim,outcome);
            end
            
            % This data structure tracks all of the trials run in the
            % experiment.  We never query it to decide what to do, but we
            % will use it to fit the data at the end.
            questDataAllTrials = qpUpdate(questDataAllTrials,stim,outcome);

        end
        btime = toc(bstart);
        fprintf('\t\tBlock time = %0.1f secs, %0.1f secs/trial\n',btime,btime/length(questOrder));
    end
end

%% Save
save(fullfile(tempdir,'qpQuestPlusColorMaterialCubicModelDemo'));

% Get stim counts
stimCounts = qpCounts(qpData(questDataAllTrials.trialData),questDataAllTrials.nOutcomes);

% Find out QUEST+'s estimate of the stimulus parameters, obtained
% on the gridded parameter domain.
psiParamsIndex = qpListMaxArg(questDataAllTrials.posterior);
psiParamsQuest = questDataAllTrials.psiParamsDomain(psiParamsIndex,:);
fprintf('Simulated parameters: %0.2f, %0.2f, %0.2f, %0.2f, %0.2f, %0.2f, %0.2f\n', ...
    simulatedPsiParams(1),simulatedPsiParams(2),simulatedPsiParams(3),simulatedPsiParams(4), ...
    simulatedPsiParams(5),simulatedPsiParams(6),simulatedPsiParams(7));
fprintf('Log 10 likelihood of data given simulated params: %0.2f\n', ...
    qpLogLikelihood(stimCounts,questDataAllTrials.qpPF,simulatedPsiParams)/log(10));
fprintf('Max posterior QUEST+ parameters: %0.2f, %0.2f, %0.2f, %0.2f, %0.2f, %0.2f, %0.2f\n', ...
    psiParamsQuest(1),psiParamsQuest(2),psiParamsQuest(3),psiParamsQuest(4), ...
    psiParamsQuest(5),psiParamsQuest(6),psiParamsQuest(7));
fprintf('Log 10 likelihood of data quest''s max posterior params: %0.2f\n', ...
    qpLogLikelihood(stimCounts,questDataAllTrials.qpPF, psiParamsQuest)/log(10));

if (SIMULATE)
    stimCounts1 = qpCounts(qpData(questDataAllTrials1.trialData),questDataAllTrials1.nOutcomes);
    fprintf('Log 10 likelihood of data given simulated params and by hand simulated responses: %0.2f\n', ...
    qpLogLikelihood(stimCounts1,questDataAllTrials1.qpPF,simulatedPsiParams)/log(10));
end
    

% Maximum likelihood fit.  Use psiParams from QUEST+ as the starting
% parameter for the search, and impose as parameter bounds the range
% provided to QUEST+.
psiParamsFit = qpFit(questDataAllTrials.trialData,questDataAllTrials.qpPF,psiParamsQuest(:),questDataAllTrials.nOutcomes,...
    'lowerBounds', [1/upperLin -upperQuad -upperCubic 1/upperLin -upperQuad -upperCubic 0], ...
    'upperBounds',[upperLin upperQuad upperCubic upperLin upperQuad upperCubic 1]);
fprintf('Maximum likelihood fit parameters: %0.2f, %0.2f, %0.2f, %0.2f, %0.2f, %0.2f, %0.2f\n', ...
    psiParamsFit(1),psiParamsFit(2),psiParamsFit(3),psiParamsFit(4), ...
    psiParamsFit(5),psiParamsFit(6),psiParamsFit(7));
fprintf('Log 10 likelihood of data fit max likelihood params: %0.2f\n', ...
    qpLogLikelihood(stimCounts,questDataAllTrials.qpPF, psiParamsFit)/log(10));
fprintf('\n');

%% Plot for last run
%
% Point transparancy visualizes number of trials (more opaque -> more
% trials), while point color visualizes dominant response.  The proportion plotted
% for each angle is the proportion of the dominant response.  This isn't as fancy
% as the Mathematica plot showin in Figure 17 of the paper, but conveys the same
% general idea of what happened.
figure; clf; hold on
stimCounts = qpCounts(qpData(questDataAllTrials.trialData),questDataAllTrials.nOutcomes);
stimProportions = qpProportions(stimCounts,questDataAllTrials.nOutcomes);
stim = zeros(length(stimCounts),questDataAllTrials.nStimParams);
for cc = 1:length(stimCounts)
    stim(cc,:) = stimCounts(cc).stim;
    nTrials(cc) = sum(stimCounts(cc).outcomeCounts);
end
for cc = 1:length(stimCounts)
    % Connect color and material match points.
    h = plot3([stim(cc,1) stim(cc,2)],[stim(cc,2) stim(cc,4)],[0 1],'-','LineWidth',3,'Color',[stimProportions(cc).outcomeProportions(1) 1-stimProportions(cc).outcomeProportions(1) 0]);
    
    % Plot the color match point as a square. Red versus green indictes proportion of color match points chosen,
    % transparency indicates number of trials.
    scatter3(stim(cc,1),stim(cc,3),0,100,'s', ...
        'MarkerEdgeColor',[stimProportions(cc).outcomeProportions(1) 1-stimProportions(cc).outcomeProportions(1) 0], ...
        'MarkerFaceColor',[stimProportions(cc).outcomeProportions(1) 1-stimProportions(cc).outcomeProportions(1) 0], ...
        'MarkerFaceAlpha',nTrials(cc)/max(nTrials),'MarkerEdgeAlpha',nTrials(cc)/max(nTrials));
    
    % Plot the material point as a circle.Red versus green indictes proportion of color match points chosen,
    % transparency indicates number of trials.
    scatter3(stim(cc,2),stim(cc,4),1,100,'o', ...
        'MarkerEdgeColor',[stimProportions(cc).outcomeProportions(1) 1-stimProportions(cc).outcomeProportions(1) 0], ...
        'MarkerFaceColor',[stimProportions(cc).outcomeProportions(1) 1-stimProportions(cc).outcomeProportions(1) 0], ...
        'MarkerFaceAlpha',nTrials(cc)/max(nTrials),'MarkerEdgeAlpha',nTrials(cc)/max(nTrials));
end
xlim([-3 3]);
ylim([-3 3]);
zlim([0 1]);
xlabel('Color Coordinate');
ylabel('Material Coordinate');
zlabel('Stim Indicator');
title({'Color Material Model',''});
drawnow;

%% Plot of posterior entropy versus trial number
if (~questDataAllTrials.noentropy)
    figure; clf; hold on
    plot(questDataAllTrials.entropyAfterTrial,'ro','MarkerSize',8,'MarkerFaceColor','r');
    ylim([0 ceil(max(questDataAllTrials.entropyAfterTrial))]);
    xlabel('Trial Number')
    ylabel('Entropy')
    title({'Color Material Model',''});
end
