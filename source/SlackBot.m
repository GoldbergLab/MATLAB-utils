classdef SlackBot
    properties
        Authorized (1, 1) logical = false
        SlackUser char = ''
        SlackTeam char = ''
    end
    properties (Access=private)
        AuthToken char = ''
        APIBaseAddress = 'https://slack.com/api'
    end
    methods
        function obj = SlackBot(options)
            arguments
                options.AuthToken char = ''
                options.AuthFile char = ''
            end
            if ~isempty(options.AuthToken)
                obj.AuthToken = options.AuthToken;
            end
            if ~isempty(options.AuthFile)
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
                obj.SlackUser = authUser;
                obj.SlackTeam = authTeam;
            else
                obj.Authorized = false;
                error('Authorization failed');
            end
        end
    end
    methods (Access=protected )
        function request = addHeaderAuth(obj, request)
            k = length(request.Header)+1;
            request.Header(k).Name = 'Authorization';
            request.Header(k).Value = sprintf('Bearer %s', obj.AuthToken);
        end
        function uri = GetURI(obj, APIMethod)
            import matlab.net.*
            import matlab.net.http.*
            uri = URI(fullfile(obj.APIBaseAddress, APIMethod));
        end
    end
    methods (Static)
        function request = addBodyDataFields(request, keys, values)
            if ~iscell(keys)
                keys = {keys};
            end
            if ~iscell(values)
                values = {values};
            end
            if length(keys) ~= length(values)
                error('Must provide the same # of values and keys');
            end
            for k = 1:length(keys)
                if isempty(request.Body)
                    request.Body(1).Data = struct();
                end
                request.Body.Data.(keys{k}) = values{k};
            end
        end
        function request = CreateRequest(method)
            arguments
                method {mustBeMember(method, {'GET', 'POST'})} = 'GET'
            end
            import matlab.net.*
            import matlab.net.http.*
            request = RequestMessage(method);
        end
        function text = addFooter(text)
            user = getenv('username');
            hostname = getenv('COMPUTERNAME');
            if isempty(hostname)
                hostname = getenv('HOSTNAME');
            end
            host = java.net.InetAddress.getLocalHost();
            if isempty(hostname)
                hostname = host.getHostName();
            end
            ipAddress = host.getHostAddress();

            text = [text, sprintf('\n\n`Message sent from MATLAB SlackBot by user logged in as %s from host %s (%s)`', user, hostname, ipAddress)];
        end
    end
    methods
        function [authOk, authUser, authTeam] = TestAuth(obj)
            request = obj.CreateRequest();
            request = obj.addHeaderAuth(request);
            uri = obj.GetURI('auth.test');
            response = send(request, uri);
            authOk = response.Body.Data.ok;
            authUser = response.Body.Data.user;
            authTeam = response.Body.Data.team;
        end
        function response = PostMessage(obj, channelID, text)
            request = obj.CreateRequest('POST');
            request = obj.addHeaderAuth(request);
            uri = obj.GetURI('chat.postMessage');

            text = obj.addFooter(text);

            request = obj.addBodyDataFields(request, {'channel', 'text'}, {channelID, text});
            response = send(request, uri);
        end
    end
end