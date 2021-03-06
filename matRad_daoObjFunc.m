function [f, g] = matRad_daoObjFunc(apertureInfoVect,apertureInfo,dij,cst)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% matRad objective function for direct aperture optimization
%
% call
%   [f, g] = matRad_daoObjFunc(apertureInfoVect,apertureInfo,dij,cst)   
%
% input
%   apertureInfoVect: aperture info in form of vector
%   apertureInfo:     aperture info struct
%   dij:              matRad dij struct as generated by bixel-based dose calculation
%   cst:              matRad cst struct
%
% output
%   f: objective function value
%   g: gradient
%
% References
%   [1] http://dx.doi.org/10.1118/1.4914863
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Copyright 2015, Mark Bangert, on behalf of the matRad development team
%
% m.bangert@dkfz.de
%
% This file is part of matRad.
%
% matrad is free software: you can redistribute it and/or modify it under
% the terms of the GNU General Public License as published by the Free
% Software Foundation, either version 3 of the License, or (at your option)
% any later version.
%
% matRad is distributed in the hope that it will be useful, but WITHOUT ANY
% WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
% details.
%
% You should have received a copy of the GNU General Public License in the
% file license.txt along with matRad. If not, see
% <http://www.gnu.org/licenses/>.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% update apertureInfo, bixel weight vector an mapping of leafes to bixels
apertureInfo = matRad_daoVec2ApertureInfo(apertureInfo,apertureInfoVect);

if nargout > 1 % calculate f and g
    
    % bixel based objective function and gradient calculation
    [f, bixelG] = matRad_objFunc(apertureInfo.bixelWeights,dij,cst);
    
    % allocate gradient vector for aperture weights and leaf positions
    g = NaN * ones(size(apertureInfoVect,1),1);
    
    % 1. calculate aperatureGrad
    % loop over all beams
    offset = 0;
    for i = 1:numel(apertureInfo.beam);

        % get used bixels in beam
        ix = ~isnan(apertureInfo.beam(i).bixelIndMap);

        % loop over all shapes and add up the gradients x openingFrac for this shape
        for j = 1:apertureInfo.beam(i).numOfShapes            
            g(j+offset) = apertureInfo.beam(i).shape(j).shapeMap(ix)' ...
                            * bixelG(apertureInfo.beam(i).bixelIndMap(ix));
        end
        
        % increment offset
        offset = offset + apertureInfo.beam(i).numOfShapes;
    
    end

    % 2. find corresponding bixel to the leaf Positions and aperture 
    % weights to calculate the gradient
    g(apertureInfo.totalNumOfShapes+1:end) = ...
            apertureInfoVect(apertureInfo.mappingMx(apertureInfo.totalNumOfShapes+1:end,2)) ...
         .* bixelG(apertureInfo.bixelIndices(apertureInfo.totalNumOfShapes+1:end)) / apertureInfo.bixelWidth;
    
    % correct the sign for the left leaf positions
    g(apertureInfo.totalNumOfShapes+1:apertureInfo.totalNumOfShapes+apertureInfo.totalNumOfLeafPairs) = ...
        -g(apertureInfo.totalNumOfShapes+1:apertureInfo.totalNumOfShapes+apertureInfo.totalNumOfLeafPairs);

else % only calculate f
    
    % bixel based objective function calculation
    f = matRad_objFunc(apertureInfo.bixelWeights,dij,cst);

end