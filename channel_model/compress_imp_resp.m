function comp_imp_resp = compress_imp_resp(imp_resp, cutoff_point)
%COMPRESS_IMP_RESP function compresses the full BELLHOP impulse response
% to include fewer multipath components
%
%INPUTS:
% IMP_RESP - structure containing all attenuation, phase shift and delay of every path
% CUTOFF_POINT - number between 0 and 1, specifying the proportion of total energy included in the
%                compressed impulse response, e.g. 0.95 or 0.99
%
%OUTPUTS:
% COMP_IMP_RESP - updated structure containing the strongest multipath components 
%                 making up the specified proportion of the total energy

% Copyright 2020 Nils Morozs, University of York (nils.morozs@york.ac.uk)
%
% Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
% associated documentation files (the "Software"), to deal in the Software without restriction,
% including without limitation the rights to use, copy, modify, merge, publish, distribute,
% sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all copies or substantial
% portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
% NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
% NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
% OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
% CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

% This work was supported by the UK Engineering and Physical Sciences Research Council (EPSRC) 
% through the USMART Project under Grant EP/P017975/1.

% By default use 0.95 cutoff point
if (nargin < 2)
    cutoff_point = 0.95;
end

% If there are no echoes in this impulse response, return the same structure
if imp_resp.num_echoes == 0
    comp_imp_resp = imp_resp;
    return;
end

% Now sort the compressed echoes from strongest to weakest 
[sorted_ampl, ind] = sort(imp_resp.ampl, 'descend');

% Only include echoes that make up at least X% of power
power_cumsum = cumsum(sorted_ampl.^2);
num_strongest_echoes = find(power_cumsum./power_cumsum(end) >= cutoff_point, 1, 'first');

% Create a new structure for the compressed impulse response
comp_imp_resp.num_echoes = num_strongest_echoes;
comp_imp_resp.ampl = imp_resp.ampl(ind(1:num_strongest_echoes));
comp_imp_resp.phase_shift = imp_resp.phase_shift(ind(1:num_strongest_echoes));
comp_imp_resp.delay = imp_resp.delay(ind(1:num_strongest_echoes));