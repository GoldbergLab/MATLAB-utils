classdef SlackBot < handle
    % A class for handling interactions with a Slack workspace from MATLAB
    properties
        Authorized (1, 1) logical = false               % Authorization successful?
        SlackBotUser char = ''                             % Name of authorized Slack user
        Workspace char = ''                             % Name of authorized Slack workspace
    end
    properties (Access=private)
        AuthToken char = ''                             % Slack API token
        APIBaseAddress = 'https://slack.com/api'        % Base address for Slack API
        Request matlab.net.http.RequestMessage          % Current HTTP request object
        Uri matlab.net.URI                              % Current HTTP URI
        Response matlab.net.http.ResponseMessage        % Last HTTP response object
        ChannelInfo struct                              % Cached copy of the Slack workspace channel list
        UserInfo struct                                 % Cached copy of the Slack workspace user list
    end
    methods
        function obj = SlackBot(options)
            arguments
                options.AuthToken char = ''     % A char array representing a Slack auth token
                options.AuthFile char = ''      % Path to a plain text file containing a Slack auth token
            end
            % Create a SlackBot
            if ~isempty(options.AuthToken)
                % User just straight up passed in an auth token
                obj.AuthToken = options.AuthToken;
            elseif ~isempty(options.AuthFile)
                % User passed in the path to an auth file - 
                if isfile(options.AuthFile)
                    fid = fopen(options.AuthFile);
                    obj.AuthToken = strip(char(fread(fid)'));
                    fclose(fid);
                    if isempty(obj.AuthToken)
                        error('No auth token found in file "%s', options.AuthFile);
                    end
                else
                    error('Auth file "%s" not found', options.AuthFile);
                end
            end
            if isempty(options.AuthToken) && isempty(options.AuthFile)
                error('You must provide either AuthToken or AuthFile argument.')
            end

            [authOk, authUser, authTeam] = obj.TestAuth();

            if authOk
                obj.Authorized = true;
                obj.SlackBotUser = authUser;
                obj.Workspace = authTeam;
            else
                obj.Authorized = false;
                error('Authorization failed');
            end
        end
    end
    methods (Access=protected)
        function CheckResponse(obj)
            % Check if the most recent response contains an error message.
            % If so, throw an error.
            if ~strcmp(obj.Response.StatusCode, 'OK')
                error('Slack error: %s', obj.Response.StatusCode);
            end
            if isstruct(obj.Response.Body.Data) && ~obj.Response.Body.Data.ok
                error('Slack error: %s', obj.Response.Body.Data.error);
            end
        end
        function addHeaderAuth(obj)
            % Add the authorization token to the header of the current 
            % request
            k = length(obj.Request.Header)+1;
            obj.Request.Header(k).Name = 'Authorization';
            obj.Request.Header(k).Value = sprintf('Bearer %s', obj.AuthToken);
        end
        function InitializeAPIURI(obj, APIMethod)
            arguments
                obj SlackBot
                APIMethod char
            end
            % Initialize the current URI using a slack API method name
            import matlab.net.*
            import matlab.net.http.*
            obj.Uri = URI(fullfile(obj.APIBaseAddress, APIMethod));
        end
        function InitializeURI(obj, url)
            arguments
                obj SlackBot
                url char
            end
            % Initialize the current URI using an arbitrary url
            import matlab.net.*
            import matlab.net.http.*
            obj.Uri = URI(url);
        end
        function setRequestPayload(obj, payload)
            % Set the raw POST payload bytes (rather than use a structured 
            % query as in addRequestQuery)
            if obj.Request.Method ~= 'POST' %#ok<BDSCA> 
                error('Set request payload is only valid for POST requests.');
            end
            if isempty(obj.Request.Body)
                obj.Request.Body(1).Data = struct();
            end
            obj.Request.Body.Payload = payload;
        end
        function addRequestQuery(obj, keys, values)
            arguments
                obj SlackBot
                keys
                values
            end
            % Add a structured query to the request for either GET or POST 
            % methods
            if ~iscell(keys)
                keys = {keys};
            end
            if ~iscell(values)
                values = {values};
            end
            if length(keys) ~= length(values)
                error('Must provide the same # of values and keys');
            end
            switch obj.Request.Method
                case 'POST'
                    for k = 1:length(keys)
                        key = keys{k};
                        value = values{k};
                        if isempty(obj.Request.Body)
                            obj.Request.Body(1).Data = struct();
                        end
                        obj.Request.Body.Data.(key) = value;
                    end
                case 'GET'
                    queryParams = matlab.net.QueryParameter.empty();
                    for k = 1:length(keys)
                        key = keys{k};
                        value = values{k};
                        queryParams(end+1) = matlab.net.QueryParameter(key, value); %#ok<AGROW> 
                    end
                    obj.Uri.Query = queryParams;
                otherwise
                    error('Unsupported request method: %s', obj.Request.Method);
            end
        end
        function InitializeRequest(obj, method, options)
            arguments
                obj SlackBot
                method {mustBeMember(method, {'GET', 'POST'})} = 'GET'
                options.AddAuth = true
            end
            % Start a new request with the given method
            import matlab.net.*
            import matlab.net.http.*
            obj.Request = RequestMessage(method);
            if options.AddAuth
                obj.addHeaderAuth();
            end
        end
        function userID = getUserID(obj, userNameOrID)
            % Get the user ID from an unknown user specifier (either 
            % a name with or without a "@" prefix or a user ID)
            userInfo = obj.GetUserInfo();
            % Get rid of leading @ if it was provided
            userNameOrID = regexprep(userNameOrID, '@', '');
            % Check if this is already an ID
            userIdx = find(strcmp(userNameOrID, {userInfo.id}), 1);
            if ~isempty(userIdx)
                userID = userNameOrID;
                return
            end
            % Must be a name instead
            userIdx = find(strcmp(userNameOrID, {userInfo.name}), 1);
            if ~isempty(userIdx)
                userID = userInfo(userIdx).id;
                return
            end
            % Not a name or an id
            error('Unknown channel name or ID: %s', userNameOrID);
        end
        function channelID = getChannelID(obj, channelNameOrID)
            % Get the channel ID from an unknown channel specifier (either 
            % a name with or without a "#" prefix or an ID)
            channelInfo = obj.GetChannelInfo();
            % Get rid of leading # if it was provided
            channelNameOrID = regexprep(channelNameOrID, '#', '');
            % Check if this is already an ID
            channelIdx = find(strcmp(channelNameOrID, {channelInfo.id}), 1);
            if ~isempty(channelIdx)
                channelID = channelNameOrID;
                return
            end
            % Must be a name instead
            channelIdx = find(strcmp(channelNameOrID, {channelInfo.name}), 1);
            if ~isempty(channelIdx)
                channelID = channelInfo(channelIdx).id;
                return
            end
            % Not a name or an id
            error('Unknown channel name or ID: %s', channelNameOrID);
        end
    end
    methods
        function userInfo = GetUserInfo(obj, options)
            arguments
                obj SlackBot
                options.ForceRefresh logical = false
            end
            % If user information is cached, return it. Otherwise, get 
            % all user information from the Slack workspace and cache it
            % for future use
            if options.ForceRefresh || isempty(obj.UserInfo)
                obj.InitializeRequest('GET');
                obj.InitializeAPIURI('users.list');
                obj.SendRequest();
                % Gather channel info into a struct array
                users = obj.Response.Body.Data.members;
                userInfo = concatenateStructures(users{:});
                % Cache result
                obj.UserInfo = userInfo;
            else
                % Just use cache
                userInfo = obj.UserInfo;
            end
        end
        function channelInfo = GetChannelInfo(obj, options)
            arguments
                obj SlackBot
                options.ForceRefresh logical = false
                options.IncludeDMs logical = false
            end
            % If channel information is cached, return it. Otherwise, get 
            % all channel information from the Slack workspace and cache it
            % for future use
            if options.ForceRefresh || isempty(obj.ChannelInfo)
                obj.InitializeRequest('GET');
                obj.InitializeAPIURI('conversations.list');
                if options.IncludeDMs
                    obj.addRequestQuery({'types'}, {'public_channel,private_channel,mpim,im'});
                end
                obj.SendRequest();
                % Gather channel info into a struct array
                channels = obj.Response.Body.Data.channels;
                channelInfo = concatenateStructures(channels{:});
                % Cache result
                obj.ChannelInfo = channelInfo;
            else
                % Just use cache
                channelInfo = obj.ChannelInfo;
            end
        end
        function [authOk, authUser, authTeam] = TestAuth(obj)
            % Check if Slack authentication succeeded
            obj.InitializeRequest('GET');
            obj.InitializeAPIURI('auth.test');
            obj.SendRequest();
            authOk = obj.Response.Body.Data.ok;
            authUser = obj.Response.Body.Data.user;
            authTeam = obj.Response.Body.Data.team;
        end
        function PostMessage(obj, channelID, text, options)
            arguments
                obj SlackBot
                channelID char
                text char
                options.CheckChannelID = true
            end
            if options.CheckChannelID
                % Ensure the channelID is a valid ID
                channelID = obj.getChannelID(channelID);
            end
            obj.InitializeRequest('POST');
            obj.InitializeAPIURI('chat.postMessage');

            text = obj.addFooter(text);

            obj.addRequestQuery({'channel', 'text'}, {channelID, text});
            obj.SendRequest();
        end
        function SendRequest(obj)
            % Send the current request to Slack
            obj.Response = send(obj.Request, obj.Uri);
            obj.CheckResponse()
        end
        function PostGraphics(obj, graphics, channel, text)
            arguments
                obj SlackBot
                graphics matlab.graphics.Graphics
                channel char = ''
                text char = ''
            end
            if isempty(channel)
                channelInfo = obj.GetChannelInfo();
                channelInfo = channelInfo([channelInfo.is_member]);
                % Get channel with GUI
                [indx, tf] = listdlg(...
                    'PromptString', {'What channel would you like', 'to post the image to?'}, ...
                    'ListString', {channelInfo.name}, ...
                    'SelectionMode', 'single');
                if ~tf
                    % No user selection
                    return
                end
                channel = channelInfo(indx).name;
            end
            % Get temp filename
            tempGraphicsFilename = [tempname(), '.png'];
            try
                % Export graphics object to file
                exportgraphics(graphics, tempGraphicsFilename);
                % Upload graphics object to Slack channel
                obj.UploadFile(tempGraphicsFilename, channel, text);
                if exist(tempGraphicsFilename, 'file')
                    % Clean up temp file
                    delete(tempGraphicsFilename);
                end
            catch ME
                if exist(tempGraphicsFilename, 'file')
                    % Make sure temp file gets cleaned up
                    delete(tempGraphicsFilename);
                end
                rethrow(ME);
            end

        end
        function UploadFile(obj, filepath, channel, text)
            arguments
                obj SlackBot
                filepath char
                channel char = ''
                text char = ''
            end
            % Upload a file to slack
            if ~exist(filepath, 'file')
                error('File "%s" not found.', filepath);
            end

            % Request upload link from Slack
            obj.InitializeRequest('GET');
            obj.InitializeAPIURI('files.getUploadURLExternal');
            [~, filename, ext] = fileparts(filepath);
            filename = [filename, ext];
            finfo = dir(filepath);
            filesize = num2str(finfo.bytes);
            obj.addRequestQuery({'filename', 'length'}, {filename, filesize});
            obj.SendRequest();

            uploadURL = obj.Response.Body.Data.upload_url;
            fileID = obj.Response.Body.Data.file_id;

            % POST file data to upload link'
            obj.InitializeRequest('POST');
            obj.InitializeURI(uploadURL);
            fid = fopen(filepath);
            fileBytes = fread(fid, '*uint8');
            fclose(fid);
            obj.setRequestPayload(fileBytes);
            obj.SendRequest();

            % Tell Slack to finalize upload
            obj.InitializeRequest('POST');
            obj.InitializeAPIURI('files.completeUploadExternal');
            files.id = fileID;
            files.title = filename;
            keys = {};
            values = {};
            keys{end+1} = 'files';
            values{end+1} = {files};
            if ~isempty(channel)
                % Ensure the channelID is a valid ID
                channel = obj.getChannelID(channel);
                
                keys{end+1} = 'channel_id';
                values{end+1} = channel;
            end
            if ~isempty(text)
                text = SlackBot.addFooter(text);
                keys{end+1} = 'initial_comment';

                values{end+1} = text;
            end

            obj.addRequestQuery(keys, values);
            obj.SendRequest();
        end
        function SendDM(obj, users, text)
            arguments
                obj SlackBot
                users {mustBeText}
                text {mustBeText}
            end
            obj.InitializeRequest('POST');
            obj.InitializeAPIURI('conversations.open');

            text = obj.addFooter(text);

            % Normalize input - should be a cell array of one or more char arrays
            if istext(users)
                if contains(users, ',')
                    % This is a comma separated string - split it
                    users = split(users, ',')';
                end
                if isstring(users)
                    if length(users) > 1
                        % Multiple elements string array
                        % Convert to cell array of char
                        users = arrayfun(@(x)char(x), users, 'UniformOutput', false);
                    else
                        % Single string - convert to char
                        users = char(users);
                    end
                elseif ischar(users)
                    users = {users};
                end
            end

            % Convert any usernames to user ids
            users = cellfun(@(userNameOrId)obj.getUserID(userNameOrId), users, 'UniformOutput', false);

            if isempty(users)
                % Get user with GUI
                userInfo = obj.GetUserInfo();
                userInfo = userInfo(~[userInfo.deleted] & ~[userInfo.is_bot]);
                [~, sortedIdx] = sort({userInfo.name});
                userInfo = userInfo(sortedIdx);
                
                [indx, tf] = listdlg(...
                    'PromptString', {'What user(s) would you like?', 'to send a message to ?'}, ...
                    'ListString', {userInfo.name}, ...
                    'SelectionMode', 'multiple');
                if ~tf || isempty(indx)
                    % No user selection
                    return
                end
                users = {userInfo(indx).name};
            end
            if isstring(users)
                users = join(users, ',');
            end
            if iscell(users)
                users = join(users, ',');
                users = users{1};
            end

            obj.addRequestQuery({'users'}, {users});
            obj.SendRequest();            

            % Get DM channel ID from response
            channelID = obj.Response.Body.Data.channel.id;
            
            obj.PostMessage(channelID, text, 'CheckChannelID', false);
        end
    end
    methods (Static, Access=protected)
        function text = addFooter(text)
            % Add an identifying footer to the Slack message
            user = strip(getenv('username'));
            if isempty(user)
                user = 'unknown';
            end
            hostname = getenv('COMPUTERNAME');
            if isempty(hostname)
                hostname = getenv('HOSTNAME');
            end
            host = java.net.InetAddress.getLocalHost();
            if isempty(hostname)
                hostname = host.getHostName();
            end
            if isempty(hostname)
                hostname = 'unknown';
            end
            ipAddress = host.getHostAddress();
            if isempty(ipAddress)
                ipAddress = 'unknown';
            end

            text = [text, sprintf('\n\n`Message sent from MATLAB SlackBot by user logged in as %s from host %s (%s)`', user, hostname, ipAddress)];
        end
    end
end