classdef CoSimInt < handle
    %COSIMINT Co-Simulation Interface

    properties
        savePath
        savePathLocal               % Where to save the co-simulation data
        savePathLocalSimdataLocal   % Save path for the local data
        savePathLocalSimdataRemote  % Save path for the remote data
        savePathRemote              %
        savePathRemoteSimdataLocal  %
        savePathRemoteSimdataRemote %
        simulatorFunction           % Function name of the simulator. Must be on Matlab path

        cosimName                   % Name of the co-simulation. Must be the same for both servers. Is also equal to the branch name that is used for data exchange

        % Git settings
        repoUrl = '';               % Repository URL
        gitUsername = 'xxx';        % Git username
        accessToken = '';           % Access token to the repo
        branchName = '';            % Branch name
        savePathRepo = '';          % Where to save the git repo?
        repoName = '';              % Name of the repo. Automatically set.
        repoPath = '';              % TODO: noch nötig?

        serverName = 'Server Name'; % Server name
        server = '';                % Server A or B
        serverA                     % Server A
        serverB                     % Server B
        MGI                         % MatlabGitInterface
        pathOut                     % Output path to the git repo
        pathIn                      % Input path from the git repo
        latestFileTimestamp         % Local timestamp of the latest file from the git repo
        lastInputFilename
        timeout                     % Timeout in seconds
        saveFilename                % Filename of the mat-File

        logFilename = '';           % Filename of the log file
        log = true;                 % Logging?
        logError = true;
        debugMsg = true;            % Debug messages?
        initFail = false;           % Is true if initialization was successful
        gitRepoReady = false;
        version = '0.4.0';
    end

    methods
        function obj = CoSimInt(param)
            % CoSimInt Constructor
            disp("-------------------------");
            disp("|<strong>Co-Simulation Interface</strong>|");
            disp("-------------------------");

            checkParam = true;

            if isfield(param,'cosimName')
                obj.cosimName = regexprep(param.cosimName, ' ', '_');
                obj.branchName = obj.cosimName;
            else
                warning('cosimName is missing.');
                checkParam = false;
            end

            if isfield(param,'accessToken')
                obj.accessToken = param.accessToken;
            else
                warning('accessToken is missing.');
                checkParam = false;
            end

            if isfield(param,'savePath')
                obj.savePath = param.savePath;
                name = strcat('cosimint-data_',obj.cosimName);
                obj.savePathLocal = fullfile(obj.savePath,name);

                if ~exist(obj.savePathLocal, 'dir')
                    mkdir(obj.savePathLocal);
                end
            else
                warning('savePathLocal is missing.');
                checkParam = false;
            end

            if isfield(param,'savePathRepo')
                obj.savePathRepo = param.savePathRepo;
            elseif isfield(param,'savePath')
                obj.savePathRepo = obj.savePath;
            else
                warning('savePathRepo is missing.');
                checkParam = false;
            end

            if isfield(param,'repoUrl')
                obj.repoUrl = param.repoUrl;

                n = split(obj.repoUrl,{'/','.'});
                obj.repoName = n{end-1};
                obj.repoPath = fullfile(obj.savePathRepo, obj.repoName);
                obj.savePathRemote = fullfile(obj.savePathRepo, obj.repoName);
            else
                warning('repoUrl is missing.');
                checkParam = false;
            end

            if isfield(param,'server')
                if strcmp(param.server,'A')
                    obj.serverA = true;
                    obj.serverB = false;

                    obj.pathOut = fullfile(obj.repoPath,'simdataA');
                    obj.pathIn = fullfile(obj.repoPath,'simdataB');
                    obj.saveFilename = 'simdataA';
                else
                    obj.serverA = false;
                    obj.serverB = true;

                    obj.pathOut = fullfile(obj.repoPath,'simdataB');
                    obj.pathIn = fullfile(obj.repoPath,'simdataA');
                    obj.saveFilename = 'simdataB';
                end
            else
                warning('server is missing.');
                checkParam = false;
            end

            if isfield(param,'serverName')
                obj.serverName = param.serverName;
            else
                if obj.serverA
                    obj.serverName = 'Server A';
                else
                    obj.serverName = 'Server B';
                end
            end

            if ~isempty(obj.serverName)
                obj.logFilename = sprintf('log_%s.log',regexprep(obj.serverName, ' ', '_'));
            else
                warning('logFilename is missing.');
                checkParam = false;
            end

            if isfield(param,'simulatorFunction')
                obj.simulatorFunction = param.simulatorFunction;
            else
                warning('server is missing.');
                checkParam = false;
            end

            if isfield(param,'log')
                obj.log = param.log;
            end

            if isfield(param,'timeout')
                obj.timeout = param.timeout;
            else
                obj.timeout = 30;
            end

            obj.printLog("+++++++++++++++++++++++++++++++++++++++++++++");
            obj.printLog("++++++++++ Co-Simulation Interface ++++++++++");
            obj.printLog("+++++++++++++++++++++++++++++++++++++++++++++");

            obj.messageCSI(sprintf('Start initialization of the co-simulation interface (Version: %s).',obj.version));
            if checkParam
                obj.messageCSI(sprintf('- savePathLocal:        %s', obj.savePathLocal));
                obj.messageCSI(sprintf('- serverName:           %s', obj.serverName));
                obj.messageCSI(sprintf('- simulatorFunction:    %s', obj.simulatorFunction));
                obj.messageCSI(sprintf('- repoUrl:              %s', obj.repoUrl));
                obj.messageCSI(sprintf('- branchName:           %s', obj.branchName));
            end

            % Initialize the MatlabGitInterface
            if checkParam
                % Create MatlabGitInterface
                obj.MGI = MatlabGitInterface(obj.repoUrl, obj.gitUsername, obj.accessToken, obj.branchName, obj.savePathRepo);

                % Remove "old" repo
                % To avoid merge conflicts delete the directory if it already exists
                if exist(obj.repoPath,'dir')
                    obj.MGI.removeRepo();
                    obj.messageCSI('Remove old repo.');
                end

                % Clone repo
                obj.MGI.clone();
                obj.messageCSI('Clone repo.');

                % Create new branch and/or checkout
                obj.MGI.branchCheckout();
                obj.messageCSI('Create/Checkout branch.');

                % Pull branch
                obj.MGI.pull();
                obj.messageCSI('Initial pull.');
                obj.messageCSI('Git repo is ready.');
                obj.gitRepoReady = true;
            end

            obj.savePathLocalSimdataLocal = fullfile(obj.savePathLocal,'simdataLocal');
            obj.savePathLocalSimdataRemote = fullfile(obj.savePathLocal,'simdataRemote');

            if checkParam
                obj.messageCSI('Initialization completed.');
            else
                obj.messageCSI('Initialization failed.');
                obj.initFail = true;
            end


        end

        function outs = start(obj, varargin)
            if ~obj.initFail
                % Initial values
                stop = false;

                outs = [];

                counterCycle = 0;
                counterFilename = 1;

                firstCycle = true;

                switch nargin
                    case 2
                        in = varargin{1}; % Inital data
                    otherwise
                        in = 0;
                end

                obj.messageCSI('Start co-simulation.');

                while ~stop

                    obj.messageCSI(sprintf('<strong>Cycle %d</strong>', counterCycle));

                    % Simulator function handle
                    simulator = str2func(obj.simulatorFunction);

                    % Waiting on REMOTE data
                    if (obj.serverA && ~firstCycle) || obj.serverB
                        % Wait for new input from REMOTE
                        obj.messageCSI('Wait for new input from REMOTE');
                        [~, ~] = obj.waitForInput(obj.timeout);

                        % Copy latest file from REMOTE to LOCAL folder
                        obj.messageCSI('Copy latest file from REMOTE to LOCAL folder');
                        p = obj.savePathLocalSimdataRemote;
                        obj.copyLatestFile(p);

                        % Load latest file from LOCAL folder for next simulation
                        obj.messageCSI('Load latest file from LOCAL folder for next simulation');
                        [filepath, ~] = obj.getLatestInputFile();
                        tmp = load(fullfile(filepath));
                        in = tmp.out;
                    end

                    % Catch error on host from client
                    if obj.serverA && isfield(in, 'error') && in.error
                        obj.messageCSI('An error has occurred on the client and the simulation could not be executed.');
                        obj.messageCSI('Please resolve the error and restart the co-simulation on both sides.');
                        obj.messageCSI('If the error occurred due to an inappropriate input, the co-simulation can be restarted on the host with a different input.');
                        pause(60*10);
                    end

                    % Catch error on client from host

                    % Generating LOCAL data
                    % Run simulation and increase counter
                    obj.messageCSI(sprintf('Start simulator (%s): %d', obj.simulatorFunction, counterCycle));
                    obj.messageCSI("+++++++++++++++++++++++++++++++++++++++++++++");
                    

                    % RUN SIMULATOR
                    try 
                        tstart = tic;
                        
                        [stop, out] = simulator(in);
                        outs = [outs out];
                    
                        tstop = toc(tstart);

                        obj.messageCSI("+++++++++++++++++++++++++++++++++++++++++++++");
                        %in = out; % The output of simA is the input of simB
                        
                        obj.messageCSI(sprintf('Successful run of simulator (%s): %d, %s',  obj.simulatorFunction, counterCycle, obj.getFormattedTime(tstop)));
                    catch ME
                        out = [];
                        out.error = true;
                        %outs = [outs out];
                        
                        % Display error message
                        warning(getReport(ME, 'extended', 'hyperlinks', 'on'));

                        % Print error message to log file
                        if obj.log && obj.logError
                            msg = getReport(ME, 'extended', 'hyperlinks', 'off');
                            obj.printLog(msg);
                        end

                        obj.messageCSI(sprintf('Error: Simulation could not be executed successfully (%s): %d', obj.simulatorFunction, counterCycle));                   
                    end                                      

                    counterCycle = counterCycle+1;

                    % Save data to mat-files in LOCAL folder
                    [filename, counterFilename] = obj.getFilenameNoOverwrite(obj.pathOut, counterFilename); % Get the counter and filename to prevent overwriting
                    dir = obj.savePathLocalSimdataLocal;
                    obj.messageCSI(sprintf('Save data to mat-files in LOCAL folder: %s', filename));
                    obj.messageCSI(sprintf('Path: %s', fullfile(dir,filename)));
                    if ~exist(dir, 'dir')
                        mkdir(dir);
                    end
                    save(fullfile(dir,filename), 'out');

                    % Upload a file to remote
                    obj.messageCSI(sprintf('Upload latest file from LOCAL folder to REMOTE(branch=%s)', obj.branchName));
                    obj.uploadFile(fullfile(dir, filename));

                    % Stop simulation
                    if stop
                        obj.messageCSI('The co-simulation was terminated by simulator');
                        commitMsg = strcat("Upload log file from ", obj.serverName);
                        obj.MGI.addAllCommitPullPush(commitMsg);
                        break;
                    end

                    firstCycle = false;
                end
            else
                obj.messageCSI('The co-simulation could not be started. Initialization failed');
            end
        end

    end

    methods (Access = private)
        function uploadFile(obj, srcFilePath)
            tmp = split(srcFilePath,'/');
            filename = tmp{end};

            if ~exist(obj.pathOut, 'dir')
                mkdir(obj.pathOut);
            end

            copyfile(srcFilePath, fullfile(obj.pathOut,filename));
            commitMsg = strcat("Upload file ", filename, " from ", obj.serverName);
            obj.MGI.addAllCommitPullPush(commitMsg);
            %fprintf('Uploaded file %s from %s to %s', filename, srcFilePath, obj.pathOut);
        end

        function copyLatestFile(obj, destFilPath)
            obj.update();
            [filepath, ~] = obj.getLatestInputFile();
            if ~exist(destFilPath, 'dir')
                mkdir(destFilPath);
            end
            copyfile(filepath, destFilPath);
            %fprintf('Moved file %s from %s to %s', filename, filepath, destFilPath);
        end

        function update(obj)
            obj.MGI.pull();
            obj.getLatestInputFile();
        end

        function [filepath, filename] = getLatestInputFile(obj)
            [filename, ts] = obj.getlatestfile(obj.pathIn);
            if filename ~= false
                filepath = fullfile(obj.pathIn, filename);
                obj.latestFileTimestamp = ts;
            else
                filepath = false;
                obj.latestFileTimestamp = ts;
            end
        end

        function num = getLastFileNumber(obj)
            [filename, ~] = obj.getlatestfile(obj.pathOut);
            if ~islogical(filename)
                tmp = split(filename,["_", "."]);
                strNum = tmp{2};
                num = str2double(strNum);
            else
                num = 0;
            end
        end

        function [filepath, filename] = waitForInput(obj, t)
            waitingtime = t; % s;
            newWaitingtime = waitingtime;
            waitingtimeFactor = 1;
            maxWaitingtime = 120; % s
            pastTime = 0;
            wait = true;
            round = 1;
            obj.messageCSI('Start waiting for input');
            while wait             
                pause(newWaitingtime);                  % Pause the execution for some time
                pastTime = pastTime+newWaitingtime;     % New past time

                obj.messageCSI(sprintf('Waiting for input since %s', obj.getFormattedTime(pastTime)));

                oldLatestTimestamp = obj.latestFileTimestamp;
                obj.update(); % Update repo: git pull and update latestFileTimestamp
                newLatestTimestamp = obj.latestFileTimestamp;
                if isempty(oldLatestTimestamp) || newLatestTimestamp > oldLatestTimestamp

                    [filepath, filename] = obj.getLatestInputFile();
                    if length(filepath) > 1
                        obj.messageCSI(sprintf('New file received after %s: %s', obj.getFormattedTime(pastTime), filename));
                        obj.lastInputFilename = filename;
                        wait = false;
                    end
                end

                % Increase waitingtime until it reaches 120s 
                if newWaitingtime < maxWaitingtime % s
                    newWaitingtime = newWaitingtime*waitingtimeFactor;
                else
                    newWaitingtime = maxWaitingtime;
                end

                round = round+1;
            end
        end

        function messageCSI(obj,msg)
            if obj.debugMsg
                nowstr = datestr(now, 'yyyy-mm-dd HH:MM:SS:FFF');
                fullmsg = strcat(nowstr,"// CSI: ",msg);
                disp(fullmsg);

                % Exclude how long to wait so that it does not become messy 
                if obj.log && ~contains(msg,'Waiting for input since')
                    obj.printLog(fullmsg);
                end
            end
        end

        function timestr = getFormattedTime(~,time)
            if time < 60
                timestr = sprintf('%0.2fs', time);
            end
            if time >= 60 && time < 3600
                timestr = sprintf('%0.2fmin', time/60);
            end
            if time >= 3600
                timestr = sprintf('%0.2fh', time/3600);
            end
        end

        function [latestfile, timestamp] = getlatestfile(~, directory)
            %This function returns the latest file from the directory passsed as input
            %argument

            %Get the directory contents
            dirc = dir(directory);

            %Filter out all the folders.
            dirc = dirc(~cellfun(@isfolder,{dirc(:).name}));

            if ~isempty(dirc)
                %I contains the index to the biggest number which is the latest file
                [A,I] = max([dirc(:).datenum]);

                if ~isempty(I)
                    latestfile = dirc(I).name;
                    timestamp = A;
                end
            else
                latestfile = false;
                timestamp = 0;
            end

            % From: https://de.mathworks.com/matlabcentral/answers/97208-how-do-i-determine-the-most-recently-updated-file-in-a-folder-in-matlab
        end

        function [out, counter] = getFilenameNoOverwrite(obj, path, counter)
            if exist(path, 'dir')
                while true
                    filename = strcat(obj.saveFilename,'_',sprintf('%05d.mat', counter));
                    filesAndFolders = dir(path);
                    files = filesAndFolders(~[filesAndFolders.isdir]);
                    fileNames = string({files.name});

                    if ismember(filename,fileNames)
                        counter = counter+1;
                    else
                        out = filename;
                        break;
                    end
                end
            else
                out = strcat(obj.saveFilename,'_',sprintf('%05d.mat', counter));
            end
        end

        % Print the log to a local and remote file
        function printLog(obj, content)
            pathLocal = fullfile(obj.savePathLocal, obj.logFilename);
            pathRemote = fullfile(obj.repoPath, obj.logFilename);

            % Remove html code for bold console output
            content = regexprep(content, '<strong>', '+++');
            content = regexprep(content, '</strong>', '+++');

            if exist(pathLocal, 'file') == 2 % If file already exists
                % Append new content if file already exists
                oldContent = fileread(pathLocal);
                newContent = sprintf("%s\n%s", oldContent, content);
            else
                newContent = content;
            end

            % Write to local log file
            fid = fopen(pathLocal,'w');
            fprintf(fid,'%s', newContent);
            fclose(fid);

            % Copy local log file and push to repo
            if exist(obj.savePathRemote,'dir') && obj.gitRepoReady
                % Copy local log file to remote path
                copyfile(pathLocal, pathRemote);

                % Push log to repo
                % It should only be pushed a second time after 30 seconds have passed 
                pushPause = 30; % seconds
                if seconds(datetime("now")-obj.MGI.timeLastPush) > pushPause
                    commitMsg = strcat("Upload log file from ", obj.serverName);
                    obj.MGI.addAllCommitPullPush(commitMsg);
                end
            end
        end

    end
end

