function shortBaseOneSatelliteDemo

    %% Start fresh
    fprintf('\nClearing stuff\n');
    clear all;
    fprintf('\n\n');

    %% Define a 1 base/3-satellite scheme
    baseHostName = 'manta';
    satellite1HostName = 'ithaca';
    

    hostNames = {baseHostName,    satellite1HostName };
    hostIPs   = {'128.91.12.90',  '169.254.103.92' };
    hostRoles = {'base',          'satellite' };

    %% Control what is printed on the command window
    beVerbose = false;
    displayPackets = false;

    %% Use 10 second time out for all comms
    timeOutSecs = 30;

    %% Generate 50 data points for the spiral signal
    coeffPoints = 100;

    %% Record a video of the demo?
    recordVideo = true;

    %% Instantiate the UDPBaseSatelliteCommunicator object to handle all communications
    UDPobj = UDPBaseSatelliteCommunicator.instantiateObject(hostNames, hostIPs, hostRoles, beVerbose, 'transmissionMode', 'WORDS');

    %% Who the heck are we?
    iAmTheBase = contains(UDPobj.localHostName, baseHostName);
    iAmSatellite1 = contains(UDPobj.localHostName, satellite1HostName);


     %% Make packetSequences for the base
    if (iAmTheBase)
        packetSequence = designPacketSequenceForBase(UDPobj, ...
            {satellite1HostName},...
            timeOutSecs, coeffPoints);
    end

    %% Make packetSequences for satellite(s)
    if (iAmSatellite1)
        packetSequence = designPacketSequenceForSatellite1(UDPobj, ...
            satellite1HostName, ...
            timeOutSecs, coeffPoints);
    end


    %% Initiate the base / multi-satellite communication
    triggerMessage = 'Go!';                                     % Tell each satellite to start listening
    allSatellitesAreAGOMessage = 'All Satellites Are A GO!';    % Tell each satellite that all its peers are ready-to-go
    UDPobj.initiateCommunication(hostRoles,  hostNames, triggerMessage, allSatellitesAreAGOMessage, 'beVerbose', beVerbose);

    %% Init demo
    if (recordVideo && iAmTheBase)
        visualizeDemoData('open');
    end

    %% Execute communication protocol
    for packetNo = 1:numel(packetSequence)
        % Transmit packet
        [theMessageReceived, theCommunicationStatus, roundTipDelayMilliSecs] = ...
            UDPobj.communicate(packetNo, packetSequence{packetNo}, ...
                'maxAttemptsNum', 3, ...
                'beVerbose', beVerbose, ...
                'displayPackets', displayPackets...
             );

         % Update demo
         if (recordVideo && iAmTheBase)
             visualizeDemoData('add');
         end
    end % packetNo

    %% Finalize demo
    if (recordVideo && iAmTheBase)
        visualizeDemoData('close');
    end


    %% Nested function for visualizing the demo
    function visualizeDemoData(mode)
        persistent videoOBJ
        persistent radial_coeff;
        persistent cos_coeff;
        persistent sin_coeff;
        persistent sat1;
        persistent sat2;
        persistent sat3;
        persistent hFig;

        if (strcmp(mode, 'open'))
            videoOBJ = VideoWriter('UDPdata.mp4', 'MPEG-4'); % H264 format
            videoOBJ.FrameRate = 30;
            videoOBJ.Quality = 100;
            videoOBJ.open();
            return;
        elseif (strcmp(mode, 'close'))
            videoOBJ.close();
            return;
        elseif (~strcmp(mode, 'add'))
            error('Unknown mode in visualizeDemoData(): ''%s'' \n', demo);
        end

        if (packetNo == 1)
            radial_coeff = [];
            cos_coeff = [];
            sin_coeff = [];
            sat1 = [];
            sat2 = [];
            sat3 = [];
            hFig = figure(1); clf;
            set(hFig, 'Position', [1000 918 1000 420], 'Color', [1 1 1])
        end

        if (~isempty(theMessageReceived))
            if (contains(theMessageReceived.label, 'SIN_COEFF'))
                sin_coeff = cat(1,sin_coeff, theMessageReceived.data);
                sat1(numel(sat1)+1) = theMessageReceived.data;
                sat2(numel(sat2)+1) = 0;
                sat3(numel(sat3)+1) = 0;
            end

            if (contains(theMessageReceived.label, 'COS_COEFF'))
                cos_coeff = cat(1,cos_coeff, theMessageReceived.data);
                sat2(numel(sat2)+1) = theMessageReceived.data;
                sat1(numel(sat1)+1) = 0;
                sat3(numel(sat3)+1) = 0;
            end

            if (contains(theMessageReceived.label, 'RADIAL_COEFF'))
                radial_coeff = cat(1,radial_coeff, theMessageReceived.data);
                sat3(numel(sat3)+1) = theMessageReceived.data;
                sat1(numel(sat1)+1) = 0;
                sat2(numel(sat2)+1) = 0;
            end

            dataPoints = min([numel(sin_coeff) numel(cos_coeff) numel(radial_coeff)]);
            if (dataPoints > 0)
                x = radial_coeff(1:dataPoints).*cos_coeff(1:dataPoints);
                y = radial_coeff(1:dataPoints).*sin_coeff(1:dataPoints);
                maxRange = max([max(abs(x(:))) max(abs(y(:)))]);
                subplot(3,5,[1 2 6 7 11 12]);
                plot(x,y, '-', 'LineWidth', 5.0, 'Color', [0.7 0.7 0.4]); hold on; plot(x,y, '*-', 'LineWidth', 1.5); hold off;
                set(gca, 'XLim', maxRange * [-1 1], 'YLim', maxRange * [-1 1], 'FontSize', 12);
                axis 'square';
                grid 'on'
                grid on
            end

            subplot(3,5, 3:5);
            if (~isempty(sat1))
                stem(sat1, 'filled');
                hL = legend('sat-1');
                set(hL, 'FontSize', 16);
            end
            set(gca, 'XLim', [1 300], 'YLim', [-1 1], 'FontSize', 12);

            subplot(3,5, 8:10);
            if (~isempty(sat2))
                stem(sat2, 'filled');
                hL = legend('sat-2');
                set(hL, 'FontSize', 16);
            end

            set(gca, 'XLim', [1 300], 'YLim', [-1 1], 'FontSize', 12);

            subplot(3,5, 13:15);
            if (~isempty(sat3))
                stem(sat3, 'filled');
                hL = legend('sat-3');
                set(hL, 'FontSize', 16);
            end
            set(gca, 'XLim', [1 300], 'YLim', [0 1], 'FontSize', 12);
            drawnow;
            videoOBJ.writeVideo(getframe(hFig));
        end % if (~isempty(theMessageReceived))
    end % visualizeDemoData
end

%
% METHOD TO DESIGN PACKET SEQUENCE FOR SATTELITE-1
%
function packetSequence = designPacketSequenceForSatellite1(UDPobj, satelliteHostName, timeOutSecs, coeffPoints)
    % Define the communication  packetSequence
    packetSequence = {};

    % Get base host name
    baseHostName = UDPobj.baseInfo.baseHostName;

    % Satellite receiving from Base
    direction = sprintf('%s -> %s', baseHostName, satelliteHostName);
    expectedMessageLabel = sprintf('BASE(%s)_TO_SATTELITE(%s)___SENDING_SINGLE_INTEGER', baseHostName, satelliteHostName);
    packetSequence{numel(packetSequence)+1} = UDPobj.makePacket(...
        satelliteHostName, ...
        direction, ...
        expectedMessageLabel, ...
        'timeOutSecs', timeOutSecs ...                                             % Wait for this many secs to receive this message
    );

    % Satellite receiving from Base
    direction = sprintf('%s -> %s', baseHostName, satelliteHostName);
    expectedMessageLabel = sprintf('BASE(%s)_TO_SATTELITE(%s)___SENDING_CHAR_STRING', baseHostName, satelliteHostName);
    packetSequence{numel(packetSequence)+1} = UDPobj.makePacket(...
        satelliteHostName,...
        direction, ...
        expectedMessageLabel, ...
        'timeOutSecs', timeOutSecs ...                                            % Wait for this many secs to receive this message
    );

    % Satellite sending to Base
    direction = sprintf('%s <- %s', baseHostName, satelliteHostName);
    messageLabel = sprintf('SATTELITE(%s)___SENDING_SMALL_STRUCT', satelliteHostName);
    messageData = struct('a', 12, 'b', [1 2 3; 4 5 6; 7 8 9]);
    packetSequence{numel(packetSequence)+1} = UDPobj.makePacket(...
        satelliteHostName, ...
        direction, ...
        messageLabel, 'withData', messageData, ...
        'timeOutSecs', timeOutSecs ...                                            % Allow this many secs to receive ACK (from remote host) that message was received
    );

    % Satellite providing cosine coefficients whenever Base asks for one.
    for k = 1:coeffPoints
        % Satellite waits to receive trigger message from Base to send next cos-coefficient
        direction = sprintf('%s -> %s', baseHostName, satelliteHostName);
        expectedMessageLabel = sprintf('BASE(%s)_TO_SATTELITE(%s)___SEND_ME_NEXT_COS_COEFF', baseHostName, satelliteHostName);
        packetSequence{numel(packetSequence)+1} = UDPobj.makePacket(...
            satelliteHostName,...
            direction, ...
            expectedMessageLabel, ...
            'timeOutSecs', timeOutSecs ...                                            % Wait for this many secs to receive this message
        );

        direction = sprintf('%s <- %s', baseHostName, satelliteHostName);
        messageLabel = sprintf('SATTELITE(%s)___SENDING_COS_COEFF', satelliteHostName);
        messageData = cos(2*pi*k/coeffPoints);
        packetSequence{numel(packetSequence)+1} = UDPobj.makePacket(...
            satelliteHostName, ...
            direction, ...
            messageLabel, 'withData', messageData, ...
            'timeOutSecs', timeOutSecs ...                                            % Allow this many secs to receive ACK (from remote host) that message was received
        );
    end

end

%
% METHOD TO DESIGN PACKET SEQUENCE FOR BASE
%
function packetSequence = designPacketSequenceForBase(UDPobj, satelliteHostNames, timeOutSecs, coeffPoints)
    % Define the communication  packetSequence
    packetSequence = {};

    % Get base host name
    baseHostName = UDPobj.baseInfo.baseHostName;

    % Base sending to Satellite-1 the number pi
    satelliteName = satelliteHostNames{1};
    direction = sprintf('%s -> %s', baseHostName, satelliteName);
    messageLabel = sprintf('BASE(%s)_TO_SATTELITE(%s)___SENDING_SINGLE_INTEGER', baseHostName, satelliteName);
    messageData = pi;
    packetSequence{numel(packetSequence)+1} = UDPobj.makePacket(...
        satelliteName,...
        direction, ...
        messageLabel, 'withData', messageData, ...
        'timeOutSecs', timeOutSecs ...                                    % Allow timeOutSecsto receive ACK (from remote host) that message was received
    );

    % Base sending to Satellite-1 the string "tra la la #1"
    satelliteName = satelliteHostNames{1};
    direction = sprintf('%s -> %s', baseHostName, satelliteName);
    messageLabel = sprintf('BASE(%s)_TO_SATTELITE(%s)___SENDING_CHAR_STRING', baseHostName, satelliteName);
    messageData = 'tra la la #1';
    packetSequence{numel(packetSequence)+1} = UDPobj.makePacket(...
        satelliteName, ...
        direction,...
        messageLabel,  'withData', messageData, ...
        'timeOutSecs', timeOutSecs ...                                        % Allow timeOutSecs to receive ACK (from remote host) that message was received
    );



    % Satellite1 sending struct to base
    satelliteName = satelliteHostNames{1};
    direction = sprintf('%s <- %s', baseHostName, satelliteName);
    messageLabel = sprintf('SATTELITE(%s)___SENDING_SMALL_STRUCT',satelliteName);
    packetSequence{numel(packetSequence)+1} = UDPobj.makePacket(...
        satelliteName, ...
        direction,...
        messageLabel, ...
        'timeOutSecs', timeOutSecs ...                                         % Allow timeOutSecs to receive this message
    );


    for k = 1:coeffPoints
        % Tell satellite-1 to send next the cos-coefficient
        satelliteName = satelliteHostNames{1};
        direction = sprintf('%s -> %s', baseHostName, satelliteName);
        messageLabel = sprintf('BASE(%s)_TO_SATTELITE(%s)___SEND_ME_NEXT_COS_COEFF', baseHostName, satelliteName);
        packetSequence{numel(packetSequence)+1} = UDPobj.makePacket(...
            satelliteName,...
            direction, ...
            messageLabel, 'withData', 'right now, please',...
            'timeOutSecs', timeOutSecs ...                                            % Wait for this many secs to receive this message
        );

        % Read the next cos-coeff from satellite-1
        direction = sprintf('%s <- %s', baseHostName, satelliteName);
        messageLabel = sprintf('SATTELITE(%s)___SENDING_COS_COEFF', satelliteName);
        packetSequence{numel(packetSequence)+1} = UDPobj.makePacket(...
            satelliteName, ...
            direction, ...
            messageLabel, ...
            'timeOutSecs', timeOutSecs ...                                            % Allow this many secs to receive ACK (from remote host) that message was received
        );

    end
end
