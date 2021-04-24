% Simulates a little amusement park

clear;

% Constants
mu_g = 40 /60/60;           % Mean time to process person at gate (seconds to hours)
offset_g = 10 /60/60;       % Max variance in process time at the gate (seconds to hours)
mu_w = 4 ./60;              % Mean time for someone to walk from place to place (minutes to hours)
mu = [2 2.8] ./60;          % Mean time for ride to finish (minutes to hours)
offset_r = [30, 20] ./60./60;  % Max variance in ride time (seconds to hours)
capacity = [8 6];           % Ride capacity (num of people)
leave = 0.025;              % Percent chance visitor will leave due to line lengths

% State Variables
lambda = 100;           % Person arrival rate (per hour)
q_gate = 0;             % Arrival gate queue length
walking = 0;            % Number of visitors walking around park
q = [0 0];              % Ride queue lengths
busy_g = false;         % Gatekeeper busy flag
busy = [false false];   % Ride busy flag
total_in_park = 0;      % Total num of people in park
left = 0;               % Number of people who left
k = 1;                  % Loop counter

% Timing Variables
time = 0;                       % Simulation clock (hours)
max_time = 12;                  % Run sim clock until this time (hours)
t_visitor = expon(1/lambda);    % Time person arrives at park
t_enter = inf;                  % Time person enters park
t_walking = inf;                % Time visitor arrives at their destination
t_ride = [inf inf];             % Time ride finishes

% Main Simulation Loop
while time < max_time
    
    % Save data (simulation outputs) for plotting later
    t(k) = time; % t is a vector, to keep track of event times
    a(k) = q_gate + busy_g;            % Total number of people at the gate + being processed
    b(k) = walking;                    % Total number of people walking in park
    c(k) = q(1) + busy(1)*capacity(1); % Total number of people in ride 1 queue + on ride
    d(k) = q(2) + busy(2)*capacity(2); % Total number of people in ride 2 queue + on ride
    k = k + 1;
    
    % Time Scheduler
    times = [t_visitor t_enter t_walking t_ride(1) t_ride(2)]; % Next event times
    [t_min, index] = min(times);
    
    time = t_min; % Move clock

    switch index
        case 1 % if visitor arrives
            if busy_g % if gatekeeper is busy
                q_gate = q_gate + 1;   
            else
                busy_g = true;
                t_enter = time + (give_or_take(mu_g, offset_g)); % set time when gatekeeper will finish processing person
            end
            
            lambda = lambda * 0.99;
            t_visitor = time + expon(1/lambda); % time next visitor arrives
            
        case 2 % gatekeeper finishes processing person - they enter park
            walking = walking + 1;              % visitor begins walking around
            t_walking = time + (expon(mu_w) / (walking/2));     % set time when person will get to their destination - depends on num of ppl walking
            total_in_park = total_in_park + 1;  % add one person to park total
            
            if q_gate > 0 % if people are lined up at the gate
                q_gate = q_gate - 1;
                t_enter = time + (give_or_take(mu_g, offset_g)); % set time when gatekeeper will finish processing person
            else
                busy_g = false; % gatekeeper is no longer busy
                t_enter = inf;
            end
            
        case 3 % person finishes walking around
            walking = walking - 1; % no longer walking around
            
            % decide if visitor leaves
            if rand() < time/max_time % the later in the day, more likely they'll leave
                total_in_park = total_in_park - 1; % visitor leaves
                left = left + 1;
                t_walking = time + (expon(mu_w) / (walking/2)); % set time next person will finish walking
                continue;
            end
            
            % if they stay, decide what ride they go on next
            i = randi([1 length(q)]); % get ride index
            if rand() < q(i)/70 % if queue length is too long
                if rand() < leave % if person is disgruntled
                    total_in_park = total_in_park - 1; %leaves park
                    left = left + 1;
                    t_walking = time + (expon(mu_w) / (walking/2)); % set time next person will finish walking
                    continue;
                end
                walking = walking + 1;
            else % if queue isn't too long
                q(i) = q(i) + 1; % get in line
                if busy(i) == false % if the ride is not active
                    if q(i) >= capacity(i) % and there's enough ppl in line to fill the ride
                        q(i) = q(i) - capacity(i); % remove people from queue
                        t_ride(i) = time + (give_or_take(mu(i), offset_r(i))); % set time when ride will finish
                        busy(i) = true;
                    end
                end
            end
            
            t_walking = time + (expon(mu_w) / (walking/2)); % set time next person will finish walking
            
        otherwise % ride finishes
            i = index - 3; % get ride index, 3 is number of cases prior to ride cases
            
            % n people get off the ride and walk around, n = capacity
            walking = walking + capacity(i);
            t_walking = time + (expon(mu_w) / (walking/2)); % update time someone will finish walking
            
            if q(i) >= capacity(i) % if there's enough people in line
                q(i) = q(i) - capacity(i); % remove people from queue
                t_ride(i) = time + (give_or_take(mu(i), offset_r(i))); % set time when ride will finish
                busy(i) = true;
            else
                busy(i) = false;
                t_ride(i) = inf;
            end
    end
    
    % Draw the park
    cla;
    axis equal;
    axis([-10 100 0 100]);
    grid on;
    % Gate - middle-left red rect
    rectangle('Position',[20 45 5 10],'FaceColor', 'r'); %[x pos, y pos, width height]
    text(10,40,'Entry Gate','FontSize',8)
    % Ride 1 - top-right blue rect
    rectangle('Position',[90 80 4 10],'FaceColor', 'b');
    text(95,85,'Ride 1','FontSize',8)
    % Ride 2 - bottom-right blue rect 
    rectangle('Position',[90 10 4 10],'FaceColor', 'b'); 
    text(95,15,'Ride 2','FontSize',8)
    
    title([ "Time (minutes): " + time*60,
            "Num of visitors: " + total_in_park,
            "Visitors that left: " + left,
            "Total visitors: " + (total_in_park + left),
            "Waiting to enter: " + q_gate,
            "Walking: " + walking,
            "Ride 1 Active: " + busy(1) + ", In line: " + q(1),
            "Ride 2 Active: " + busy(2) + ", In line: " + q(2)]);
    
    % Add Gate queue
    x = 19;
    y = 50;
    for i = 1:q_gate
        rectangle('Position',[x y 1 1]);
        x = x-1;
    end
    
    % Add walking people
    xlim = [30 80];
    ylim = [20 80];
    for i = 1:walking
        x = randi(xlim);
        y = randi(ylim);
        rectangle('Position',[x y 1 1]);
    end
    
    % Add Ride 1's queue
    x = 89;
    y = 85;
    for i = 1:q(1)
        rectangle('Position',[x y 1 1]);
        x = x-1;
    end
    
    % Add Ride 2's queue
    x = 89;
    y = 15;
    for i = 1:q(2)
        rectangle('Position',[x y 1 1]);
        x = x-1;
    end
    
    pause(0.005)
end

% Analysis
% Add final points
t(k) = time; 
a(k) = q_gate + busy_g;  
b(k) = walking;        
c(k) = q(1) + busy(1)*capacity(1);
d(k) = q(2) + busy(2)*capacity(2);
% Plot
%show_graph(t, a, time, "People at the gate");
%show_graph(t, b, time, "People Walking");
%show_graph(t, c, time, "People in Ride 1 Queue");
%show_graph(t, d, time, "People in Ride 2 Queue");

% Returns a positive random number chosen from an exponential distribution
% with mean value 'mean'.
function e = expon(mean)
    e = -log(rand)*mean;
end

% Takes a number and adds or subtracts a random value from it given an
% upper bound offset. Returns num, give or take a number in range 0 to offset.
function t = give_or_take(num, offset)
    positive = randi([0 1]); % gets random int between 0 and 1
    if positive
        t = num + rand() * offset;
    else
        t = num + (rand() * -offset);
    end
end

function show_graph(x, y, time, message)
    stairs(x, y)
    xlim([0 time]);  % Set x axis limits, y will be auto
    xlabel("Time (hours)");
    ylabel(message);
end
