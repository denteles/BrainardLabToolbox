% Method to analyze a calStruct generated by a @Calibrator object.
function obj = analyze(obj, cal)

    % Instantiate @CalStruct object to manage the imported cal
    calStructOBJ = CalStruct(cal, 'verbosity', 1);
 
    if (calStructOBJ.inputCalHasNewStyleFormat)
        % Clear the calStructOBJ as the input cal has new-style format
        clear 'calStructOBJ';
        % set the @Calibrator's cal struct. The cal setter method also sets 
        % various other properties of obj
        obj.cal = cal;
        obj.refitData();
        obj.computeReusableQuantities();  
        obj.plotAllData();
    
        % Print cal struct
        obj.displayCalStruct();
    else
        % Clear the calStructOBJ as the input cal has new-style format
        clear 'calStructOBJ';
        % set the @Calibrator's cal struct to empty
        obj.cal = [];
        % and notify user
        calStruct.describe
        fprintf('The selected cal struct has an old-style format.\n');
        fprintf('Using ''mglAnalyzeMonCalSpd'' to analyze/plot it instead.\n');
        mglAnalyzeMonCalSpd
    end
    
    
end