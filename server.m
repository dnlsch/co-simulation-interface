%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Co-Simulation Interface %
%      Server script      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The co-simulation is started from server A (define the instance in the 
% settings). To initialize the co-simulation both server-scripts must be
% running. The starting order on both servers does not matter.
% The co-simulation can only be successful if the settings are set
% correctly.
% Server A can be considered as host and server B as client.

%%%%%%%%%%%%%%%%
%%% Settings %%%
%%%%%%%%%%%%%%%%

%% General settings

% Name of the co-simulation
% The cosimName must be exactly the same on both servers!
% The cosimName is also used as branch name.
param.cosimName = 'MyFirstCoSim';

% Path where the data should be saved
% Data from the local and remote simulator will be saved there.
param.savePath = '/path/to/sim-data';

% Define if the server is server A or B
% The simulator on server A is started first. Initial parameters are
% required for this.
param.server = 'A'; % 'A' or 'B'
%param.server = 'B';

% Define a name for the server
param.serverName = 'Comsol Server'; % e.g. 'Comsol Server'

% Function name of the local simulator. Make sure that the function is
% added to Path.
param.simulatorFunction = 'simulatorA';

% How long should the CSI wait until the next update query?
param.timeout = 5; % s

%% Git settings

% Repository Url (must be the same path on both servers!)
param.repoUrl = "url-of-git-repo.git";

% Project Access Token. Can be generated here: {repoUrl}/-/settings/access_tokens
% Role must be "Developer", Select all scopes
param.accessToken = 'secret-token';

% Repo path (where the repo should be saved locally)
% If not set it will be equal to param.savePath
% param.savePathRepo = '';

% Attention: The following settings must be the same on server A and B!
% param.repoUrl, param.cosimName

%%%%%%%%%%%%%%%%%%%%
%%%   Git Test   %%%
%%%%%%%%%%%%%%%%%%%%

% MGI Test
% Uncomment these lines to test the MatlabGitInterface with the settings
% made above.
%MGI = MatlabGitInterface(param.repoUrl, param.gitUsername, param.accessToken, param.cosimName, param.savePath);
%MGI.test();

%%%%%%%%%%%%%%%%%%%%
%%% Initial data %%%
%%%%%%%%%%%%%%%%%%%%

% Define initial data
% The initial data must be stored in one variable (structre array). 
% Furthermore, the variable must be readable by the simulator function.
% The output of one simulator function is the input of the other and vice 
% versa. It must therefore be ensured that the two simulators can each read 
% the output of the other. 

% Example
in.count = 0;
in.countA = 0;
in.countB = 0;

%%%%%%%%%%%%%%%%%
%%% Execution %%%
%%%%%%%%%%%%%%%%%

%%
% Initialze CoSimInt!
CSI = CoSimInt(param);

%%
% Start the co-simulation with the inital data. The co-simulation starts if
% the CSI is started on both servers.
% The initial data must be passed for server A.
% No parameters are passed for server B.
out = CSI.start(in); % Server A
%CSI.start(); % Server B
