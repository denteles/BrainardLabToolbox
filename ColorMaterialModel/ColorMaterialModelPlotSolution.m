function ColorMaterialModelPlotSolution(theDataProb, predictedProbabilitiesBasedOnSolution, returnedModelParams,...
    indexMatrix, params, figDir, saveFigs, weibullplots, actualProbs)
% ColorMaterialModelPlotSolution(theDataProb, predictedProbabilitiesBasedOnSolution, returnedModelParams,...
%    indexMatrix, params, figDir, saveFig, weibullplots, actualProbs)
% Make a nice plot of the data and MLDS-based model fit.
%
% Inputs:
%   theDataProb - the data probabilities measured in the experiment
%   predictedProbabilitiesBasedOnSolution - predictions based on solutions
%   returnedModelParams - returned model parameters
%   indexMatrix - matrix of indices needed for extracting only the
%                 probabilities for color/material trade-off
%   params -  standard experiment specifications structure
%   figDir -  specify figure directory
%   saveFigs - save intermediate figures? main figure is going to be saved by default. 
%   weibullplots - flag indicating whether to save weibullplots or not
%   actualProbs -  probabilities for actual parameters (ground truth) which
%                  we is known for simulated data

% 06/15/2017 ar Added comments and made small changes to the code. 

% Close all open figures; 
close all; 

% Reformat probabilities to look only at color/material tradeoff
% Indices that reformating is based on are saved in the data matrix
% that we loaded.
colorMaterialDataProb = ColorMaterialModelResizeProbabilities(theDataProb, indexMatrix);
colorMaterialSolutionProb = ColorMaterialModelResizeProbabilities(predictedProbabilitiesBasedOnSolution, indexMatrix);
subjectName = params.subjectName; 
cd (figDir)

% Unpack passed params.  
[returnedMaterialMatchColorCoords,returnedColorMatchMaterialCoords,returnedW,returnedSigma]  = ColorMaterialModelXToParams(returnedModelParams, params); 

% Set plot parameters. 
% Note: paramters this small will not look nice in single figures, but will
% look nice in the main combo-figure. 
thisFontSize = 20; 
thisMarkerSize = 20-4; 
thisLineWidth = 2; 

%% Figure 1. Plot measured vs. predicted probabilities
f1 = figure; hold on
plot(theDataProb, predictedProbabilitiesBasedOnSolution,'ro','MarkerSize',thisMarkerSize-2,'MarkerFaceColor','r');
% rmse = ComputeRealRMSE(theDataProb,predictedProbabilitiesBasedOnSolution);
% text(0.07, 0.92, sprintf('rmseFit = %.4f', rmse), 'FontSize', thisFontSize);
% if nargin == 9
%     plot(theDataProb,actualProbs,'bo','MarkerSize',thisMarkerSize-2);
%     rmseComp = ComputeRealRMSE(theDataProb,actualProbs); 
%     text(0.07, 0.82, sprintf('rmseActual = %.4f', rmseComp), 'FontSize', thisFontSize);
%     legend('Fit Parameters', 'Simulated Parameters', 'Location', 'NorthWest')
%     legend boxoff
% else
%     legend('Fit Parameters', 'Location', 'NorthWest')
%     legend boxoff
% end
line([0, 1], [0,1], 'color', 'k');
axis('square'); axis([0 1 0 1]);
set(gca,  'FontSize', thisFontSize);
xlabel('Measured p');
ylabel('Predicted p');
set(gca, 'xTick', [0, 0.5, 1]);
set(gca, 'yTick', [0, 0.5, 1]);
ax(1)=gca;
   FigureSave([subjectName, 'RMSE'], f1, 'pdf'); 
% Prepare for figure 2. Fit cubic spline to the data
% We do this separately for color and material dimension
xMin = -params.maxPositionValue;
xMax = params.maxPositionValue;
yMin = -params.maxPositionValue; 
yMax = params.maxPositionValue;

splineOverX = linspace(xMin,xMax,1000);
splineOverX(splineOverX>max(params.materialMatchColorCoords))=NaN;
splineOverX(splineOverX<min(params.materialMatchColorCoords))=NaN; 

% Find a cubic fit to the data for both color and material. 
FColor = griddedInterpolant(params.materialMatchColorCoords, returnedMaterialMatchColorCoords,'cubic');
FMaterial = griddedInterpolant(params.colorMatchMaterialCoords, returnedColorMatchMaterialCoords,'cubic');

% We evaluate this function at all values of X we're interested in. 
inferredPositionsColor = FColor(splineOverX); 
inferredPositionsMaterial  = FMaterial(splineOverX); 

%% Figure 2. Plot positions from fit versus actual simulated positions 
fColor = figure; hold on; 
plot(params.materialMatchColorCoords,returnedMaterialMatchColorCoords,'ro'); 
plot(splineOverX, inferredPositionsColor, 'r', 'MarkerSize', thisMarkerSize);
plot([xMin xMax],[yMin yMax],'--', 'LineWidth', thisLineWidth, 'color', [0.5 0.5 0.5]);
%title('Color dimension')
axis([xMin, xMax,yMin, yMax])
axis('square')
xlabel('Color "true" position');
ylabel('Inferred position');
set(gca, 'xTick', [xMin, 0, xMax],'FontSize', thisFontSize);
set(gca, 'yTick', [yMin, 0, yMax],'FontSize', thisFontSize);
ax(2)=gca;

%% Figure 2. Plot positions from fit versus actual simulated positions 
fMaterial = figure; hold on; 
plot(params.colorMatchMaterialCoords,returnedColorMatchMaterialCoords,'bo')
plot(splineOverX,inferredPositionsMaterial, 'b', 'MarkerSize', thisMarkerSize);
plot([xMin xMax],[yMin yMax],'--', 'LineWidth', thisLineWidth, 'color', [0.5 0.5 0.5]);
%title('Material dimension')
axis([xMin, xMax,yMin, yMax])
axis('square')
xlabel('Material "true" position');
ylabel('Inferred position');
set(gca, 'xTick', [xMin, 0, xMax],'FontSize', thisFontSize);
set(gca, 'yTick', [yMin, 0, yMax],'FontSize', thisFontSize);
ax(3)=gca;
if saveFigs
    FigureSave([subjectName, 'RecoveredPositionsSpline'], fColor, 'pdf'); 
    FigureSave([subjectName, 'RecoveredPositionsSpline'], fMaterial, 'pdf'); 
end

%% Plot the color and material of the stimuli obtained from the fit in the 2D representational space
f2 = figure; hold on; 
% thisMarkerSize = 16; 
% thisLineWidth = 2; 
plot(returnedMaterialMatchColorCoords, zeros(size(returnedMaterialMatchColorCoords)),'ko', ...
    'MarkerFaceColor', 'k', 'MarkerSize', thisMarkerSize, 'LineWidth', thisLineWidth); 
line([xMin, xMax], [0,0],'color', 'k'); 
plot(zeros(size(returnedColorMatchMaterialCoords)), returnedColorMatchMaterialCoords, 'ko',...
    'MarkerFaceColor', 'k', 'MarkerSize', thisMarkerSize, 'LineWidth', thisLineWidth); 
axis([xMin, xMax,yMin, yMax])
line([0,0],[yMin, yMax],  'color', 'k'); 
axis('square')
xlabel('Color', 'FontSize', thisFontSize);
ylabel('Material','FontSize', thisFontSize);
set(gca, 'xTick', [xMin, 0, xMax],'FontSize', 26);
set(gca, 'yTick', [yMin, 0, yMax],'FontSize', 26);
ax(4)=gca;

if saveFigs
  %  savefig(f2, [subjectName, 'RecoveredPositions2D.fig'])
    FigureSave([subjectName, 'RecoveredPositions2D'], f2, 'pdf'); 
end
%% Figure 3. Plot descriptive Weibull fits to the data. 
if weibullplots
    % We loop through the matrix that contains probabilities for color
    % match being chosen. Each column is a fixed material step (i.e., color
    % varies across). Each row is a fixed color step (material varies). 
    % We plot column by column (i.e. each column is going to be one line in
    % the plot). This line shows how the probability of choosing a color match  
    % of a fixed material step (index i below) varies for different degrees of 
    % color variation of the material match (x axis). Each line (column) is a fixed
    % material step. 
    for i = 1:size(colorMaterialDataProb,2);
        if i == 4
            fixMidPoint = 1;
        else
            fixMidPoint = 0;
        end
        % Plot proportion of color match chosen for different 
        % color-diffence steps of the material match.
        [theSmoothPreds(:,i), theSmoothVals(:,i)] = FitColorMaterialModelWeibull(colorMaterialDataProb(:,i)',...
            params.materialMatchColorCoords, fixMidPoint);
        
        % This is the reverse fit: we're plotting the proportion of time
        % material match is chosen for different material-difference steps of
        % the color match.
        [theSmoothPredsReverseModel(:,i), theSmoothValsReverseModel(:,i)] = FitColorMaterialModelWeibull(1-colorMaterialDataProb(i,:),...
            params.colorMatchMaterialCoords, fixMidPoint);
    end
    thisFig1 = ColorMaterialModelPlotFit(theSmoothVals, theSmoothPreds, params.colorMatchMaterialCoords, colorMaterialDataProb,...
        'whichMatch', 'colorMatch', 'whichFit', 'weibull', 'fontSize', thisFontSize, 'markerSize', thisMarkerSize, 'lineWidth', thisLineWidth);
    thisFig2 = ColorMaterialModelPlotFit(theSmoothValsReverseModel, theSmoothPredsReverseModel, params.materialMatchColorCoords, 1-colorMaterialDataProb', ...
        'whichMatch', 'materialMatch', 'whichFit', 'weibull', 'fontSize', thisFontSize, 'markerSize', thisMarkerSize, 'lineWidth', thisLineWidth);
    
    if saveFigs
        FigureSave([subjectName, 'WeibullFitColorXAxis'], thisFig1, 'pdf');
        FigureSave([subjectName, 'WeibullFitMaterialXAxis'],thisFig2, 'pdf');
    end
end
%% Plot predictions of the model through the actual data
returnedColorMatchColorCoord =  FColor(params.targetColorCoord);
returnedMaterialMatchMaterialCoord = FMaterial(params.targetMaterialCoord);

% Find the predicted probabilities for a range of possible color coordinates
rangeOfMaterialMatchColorCoordinates =  linspace(min(params.materialMatchColorCoords), max(params.materialMatchColorCoords), 100)';
% Find the predicted probabilities for a range of possible material
% coordinates - for the reverse model.

rangeOfColorMatchMaterialCoordinates =  linspace(min(params.colorMatchMaterialCoords), max(params.colorMatchMaterialCoords), 100)';
% Loop over each material coordinate of the color match, to get a predicted
% curve for each one.

for whichMaterialCoordinate = 1:length(params.colorMatchMaterialCoords)
    
    % Get the inferred material position for this color match
    % Note that this is read from cubic spline fit.
    returnedColorMatchMaterialCoord(whichMaterialCoordinate) = FMaterial(params.colorMatchMaterialCoords(whichMaterialCoordinate));
    
    % Get the inferred color position for a range of material matches
    for whichColorCoordinate = 1:length(rangeOfMaterialMatchColorCoordinates)
        % Get the position of the material match using our FColor function
        returnedMaterialMatchColorCoord(whichColorCoordinate) = FColor(rangeOfMaterialMatchColorCoordinates(whichColorCoordinate));
        
        % Compute the model predictions
        %         modelPredictions(whichColorCoordinate, whichMaterialCoordinate) = ColorMaterialModelComputeProb(params.targetColorCoord,params.targetMaterialCoord, ...
        %             returnedColorMatchColorCoord,returnedMaterialMatchColorCoord(whichColorCoordinate),...
        %             returnedColorMatchMaterialCoord(whichMaterialCoordinate), returnedMaterialMatchMaterialCoord, returnedW, returnedSigma);
        modelPredictions(whichColorCoordinate, whichMaterialCoordinate) = ColorMaterialModelGetProbabilityFromLookupTable(params.F,returnedColorMatchColorCoord,returnedMaterialMatchColorCoord(whichColorCoordinate),...
            returnedColorMatchMaterialCoord(whichMaterialCoordinate), returnedMaterialMatchMaterialCoord,returnedW);
        
    end
end
rangeOfMaterialMatchColorCoordinates = repmat(rangeOfMaterialMatchColorCoordinates,[1, length(params.materialMatchColorCoords)]);
[thisFig3, thisAxis3] = ColorMaterialModelPlotFit(rangeOfMaterialMatchColorCoordinates, modelPredictions, params.materialMatchColorCoords, colorMaterialDataProb, ...
    'whichMatch', 'colorMatch', 'whichFit', 'MLDS','returnedWeight', returnedW, ...
    'fontSize', thisFontSize, 'markerSize', thisMarkerSize, 'lineWidth', thisLineWidth);
ax(5)=thisAxis3;
FigureSave([params.subjectName, 'ModelFitColorXAxis'], thisFig3, 'pdf');

% Get values for reverse plotting
for whichColorCoordinate = 1:length(params.materialMatchColorCoords)
    
    % Get the inferred material position for this color match
    % Note that this is read from cubic spline fit.
    returnedMaterialMatchColorCoord(whichColorCoordinate) = FColor(params.materialMatchColorCoords(whichColorCoordinate));
    
    % Get the inferred color position for a range of material matches
    for whichMaterialCoordinate = 1:length(rangeOfColorMatchMaterialCoordinates)
        % Get the position of the material match using our FColor function
        returnedColorMatchMaterialCoord(whichMaterialCoordinate) = FMaterial(rangeOfColorMatchMaterialCoordinates(whichMaterialCoordinate));
        
        % Compute the model predictions
        %         modelPredictions2(whichMaterialCoordinate, whichColorCoordinate) = 1-ColorMaterialModelComputeProb(params.targetColorCoord,params.targetMaterialCoord, ...
        %             returnedColorMatchColorCoord,returnedMaterialMatchColorCoord(whichColorCoordinate),...
        %             returnedColorMatchMaterialCoord(whichMaterialCoordinate), returnedMaterialMatchMaterialCoord, ...
        %             returnedW, returnedSigma);
        
        modelPredictions2(whichMaterialCoordinate, whichColorCoordinate) = 1 - ColorMaterialModelGetProbabilityFromLookupTable(params.F,...
            returnedColorMatchColorCoord,returnedMaterialMatchColorCoord(whichColorCoordinate),...
            returnedColorMatchMaterialCoord(whichMaterialCoordinate), returnedMaterialMatchMaterialCoord, ...
            returnedW);
    end
end
rangeOfColorMatchMaterialCoordinates = repmat(rangeOfColorMatchMaterialCoordinates,[1, length(params.colorMatchMaterialCoords)]);
[thisFig4, thisAxis4] = ColorMaterialModelPlotFit(rangeOfColorMatchMaterialCoordinates, modelPredictions2, params.colorMatchMaterialCoords, 1-colorMaterialDataProb', ...
    'whichMatch', 'materialMatch', 'whichFit', 'MLDS','returnedWeight', returnedW, ...
    'fontSize', thisFontSize, 'markerSize', thisMarkerSize, 'lineWidth', thisLineWidth);
ax(6)=thisAxis4;
if saveFigs
    FigureSave([subjectName, 'ModelFitColorXAxis'], thisFig3, 'pdf');
    FigureSave([subjectName, 'ModelFitMaterialXAxis'], thisFig4, 'pdf');
end

% Combine all figures into a combo-figure.
nImagesPerRow = 3;
nImages = length(ax);
figure;
for i=1:nImages
    % Create and get handle to the subplot axes
    sPlot(i) = subplot(ceil(nImages/nImagesPerRow),nImagesPerRow,i);
    % Get handle to all the children in the figure
    aux=get(ax(i),'children');
    for j=1:size(aux)
        tmpFig(i) = aux(j);
        copyobj(tmpFig(i),sPlot(i));
        hold on
    end
    % Copy children to new parent axes i.e. the subplot axes
    xlabel(get(get(ax(i),'xlabel'),'string'));
    ylabel(get(get(ax(i),'ylabel'),'string'));
    title(get(get(ax(i),'title'),'string'));
    axis square
    if i > 4
        axis([params.colorMatchMaterialCoords(1) params.colorMatchMaterialCoords(end) 0 1.05])
    elseif i == 1
        axis([0 1.05 0 1.05])
    end
end
FigureSave([params.subjectName, 'Main'], gcf, 'pdf');
end