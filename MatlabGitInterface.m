classdef MatlabGitInterface < handle
    %MATLABGITINTERFACE

    % In short: The methods of this class generate and execute the 
    % corresponding git commands as you know them from the console

    % Since R2023b
    % https://de.mathworks.com/help/matlab/ref/gitclone.html
    % Until R2023b there is not direct git integration which makes this 
    % manual implementation necessary.
    
    properties
        repoUrl         = '';           
        gitUsername     = '';
        accessToken     = '';      
        branchName      = 'main';
        savePathRepo    = '';      

        repoName        = '';
        currentBranch   = '';      
        repoPath        = '';

        debugMsg = false;
        timeLastPush = datetime("now")
    end
    
    methods
        function obj = MatlabGitInterface(repoUrl, gitUsername, accessToken, branchName, savePathRepo)
            repoUrl = char(repoUrl);
            obj.repoUrl = repoUrl(9:end);
            obj.gitUsername = gitUsername;
            obj.accessToken = accessToken;
            obj.branchName = branchName;
            repoName = split(repoUrl,{'/','.'});
            obj.repoName = repoName{end-1};
            obj.currentBranch = 'main';
            obj.savePathRepo = savePathRepo;
            obj.repoPath = fullfile(obj.savePathRepo, obj.repoName);
        end
        
        function relPath = clone(obj)           
            if isfolder(obj.repoPath)
                obj.messageMGI('The repo cannot be cloned. The repo already exists.');   
            else
                cmd = sprintf('cd "%s" && git clone https://%s:%s@%s', obj.savePathRepo, obj.gitUsername, obj.accessToken, obj.repoUrl);
                obj.exeCmdAndPrint(cmd);
                relPath = obj.repoName;
            end            
        end

        function status(obj)           
            cmd = sprintf('cd "%s" && git status', obj.repoPath);
            obj.exeCmdAndPrint(cmd);
        end

        function pull(obj, varargin)
            switch nargin                
                case 2
                    name = varargin{1};
                otherwise
                    name = obj.branchName;                    
            end
            cmd = sprintf('cd "%s" && git pull origin %s', obj.repoPath, name);
            obj.exeCmdAndPrint(cmd);
        end

        function addAll(obj)
            cmd = sprintf('cd "%s" && git add -A', obj.repoPath);
            obj.exeCmdAndPrint(cmd);
        end

        function commit(obj, commitMsg)
            cmd = sprintf('cd "%s" && git commit -m "%s"', obj.repoPath, commitMsg);
            obj.exeCmdAndPrint(cmd);
        end

        function push(obj, varargin)
            switch nargin                
                case 2
                    name = varargin{1};
                otherwise
                    name = obj.branchName;                    
            end
            cmd = sprintf('cd "%s" && git push origin %s', obj.repoPath, name);
            obj.exeCmdAndPrint(cmd);
            obj.timeLastPush = datetime("now");
        end

        function addAllCommitPullPush(obj, commitMsg)
            obj.addAll();
            obj.commit(commitMsg);
            obj.pull();
            obj.push();
        end

        function branch(obj, varargin)
            switch nargin                
                case 2
                    name = varargin{1};
                otherwise
                    name = obj.branchName;   
            end

            cmd = sprintf('cd "%s" && git branch %s main', obj.repoPath, name);
            obj.exeCmdAndPrint(cmd);
        end

        function checkout(obj, varargin)
            switch nargin                
                case 2
                    name = varargin{1};
                otherwise
                    name = obj.branchName;   
            end
            
            cmd = sprintf('cd "%s" && git checkout %s', obj.repoPath, name);
            obj.exeCmdAndPrint(cmd);

            obj.currentBranch = name;
        end

        function branchCheckout(obj, varargin)
            switch nargin                
                case 2
                    name = varargin{1};
                    obj.branch(name);
                    obj.checkout(name);
                otherwise
                    obj.branch(obj.branchName);
                    obj.checkout(obj.branchName);    
            end
        end

        function result = branchList(obj)
            cmd = sprintf('cd "%s" && git branch',obj.repoPath);
            result = obj.exeCmdAndPrint(cmd);
        end

        function test(obj)
            fprintf('Run MGI test\n');
            fprintf('Clone repo\n');
            obj.clone();

            fprintf('Create testBranch and checkout\n');
            tempNameBranch = obj.branchName;
            obj.branchName = 'testBranch';
            obj.branchCheckout(obj.branchName);

            obj.pull();

            fprintf('Create test file\n');
            time = string(datetime('now','Format','d-MM-y_HHmmss'));
            filename = sprintf('test_%s.txt',time);
            content = 'MGI Test';
            fid = fopen(fullfile(obj.repoPath,filename),'w');
            fprintf(fid,'%s\n', content);
            fclose(fid);

            fprintf('Add, Commit and Push\n');
            obj.addAllCommitPullPush('MGI Test');

            obj.branchName = tempNameBranch;

            fprintf('Remove repo\n');
            obj.removeRepo();
        end

        function removeRepo(obj)
            rmdir(obj.repoPath, 's');
        end
        
    end

    methods (Access = private)
        function messageMGI(~,msg)
            nowstr = datestr(now, 'yyyy-mm-dd HH:MM:SS:FFF');
            disp(strcat(nowstr,"// MGI: ",msg));
        end

        function result = exeCmdAndPrint(obj, cmd)
            [~, result] = system(cmd);
            obj.printMsg(strcat("cmd > ", cmd));
            obj.printMsg(strcat(result,'\n'));
        end

        function printMsg(obj, msg)
            if obj.debugMsg
                fprintf(2,strcat(msg,'\n'));
            end
        end

        function printMsgMGI(~, msg)
            fprintf(strcat("MGI: ",msg,'\n'));
        end
    end
end
