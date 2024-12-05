%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Example Simulator %%%
%%%%%%%%%%%%%%%%%%%%%%%%%

function [stop, out] = simulatorA(in)   
    %simulatorA Example simulator
    %
    %   Input:
    %       in (structure array):
    %           - Object with some parameter that a required as input for
    %           the simulation. This object is the output of the remote
    %           simulator
    %   Output:
    %       output (structure array):
    %           - Output that is returned after the simulator. This object 
    %           is the input for the remote simulator
    %   Usage:
    %       [stop, out] = simulatorA(in)
    %
    % Only change the code in the black box!
    %
    % Inputs and outputs of the local and remote functions must match.
    % Make sure that the parameters in each function can be processed accordingly.
    %
    % To use this function as simulator make sure that the file is on the
    % Matlab path and the function name is adjusted in the settings.

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% %%%%%%%%%%
    % Black box %
    % vvvvvvvvv %

    out.count = in.count+1;
    out.countA = in.countA+1;
    out.countB = in.countB;
    %pause(20);

    % Stop condition
    % Set a stop condition to terminate the co-simulation.
    % Result must be true or false.
    % If both simulators do not have a stop condition, the co-simulation 
    % runs forever (in theory).
    stopc = out.count > 20; 
    
    % ^^^^^^^^^ %
    % Black box %
    %% %%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Test stop condition
    if stopc
        stop = true; % Co-simulation is terminated
    else
        stop = false; % Co-simulation continues
    end
end

