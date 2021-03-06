function x = ColorMaterialModelParamsToX(materialMatchColorCoords,colorMatchMaterialCoords,weight,sigma)
% x = ColorMaterialModelParamsToX(materialMatchColorCoords,colorMatchMaterialCoords,weight,sigma)
%
% Pack the parameter vector for ColorMaterialModel
%
% Input: 
%   materialMatchColorCoords - inferred positions on material dimensions for a color match
%   colorMatchMaterialCoords - inferred positions on color dimensions for a material match
%   weight - weighting of color, relative to material. 
%   sigma - noise, fixed to 1.
%
% Output: 
%   x - parameters vector
%
%   Note, target falls at some place on color and material position and
%   that position is at 0, by definition (i.e. this is an assumption
%   inhereent in our model). 

% 12/2/2016 ar, dhb Wrote it

x = [materialMatchColorCoords colorMatchMaterialCoords weight sigma]';

end



