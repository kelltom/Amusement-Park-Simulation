clear;

% Constants
lambda = 10;            % Person arrival rate (per hour)
mu_g = 20 /60/60;       % Mean time to process person at gate (seconds to hours)
offset_g = 10 /60/60;   % Max variance in process time at the gate (seconds to hours)
mu_w = 30 ./60./60;     % Mean time for someone to walk from place to place (seconds to hours)
mu = [2 3] ./60;        % Mean time for ride to finish (minutes to hours)
offset_r = [30, 20] ./60./60;  % Max variance in ride time (seconds to hours)
capacity = [8 6];       % Ride capacity (num of people)

% State Variables
q_gate = 0;             % Arrival gate queue length
walking = 0;            % Number of visitors walking around park
q = [0 0];              % Ride queue lengths
busy_g = false;         % Gatekeeper busy flag
busy = [false false];   % Ride busy flag
total_in_park = 0;      % Total num of people in park
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
            
            t_visitor = time + expon(1/lambda); % time next visitor arrives
            
        case 2 % gatekeeper finishes processing person - they enter park
            %%% WE NEED A FANCY WAY TO DETERMINE THE TIME IT TAKES FOR PERSON TO FINISH WALKING %%%
            %%% IT NEEDS TO BE BASED ON THE NUMBER OF PPL CURRENTLY WALKING (more walkers, faster they finish walking) %%%
            walking = walking + 1;              % visitor begins walking around
            t_walking = time + expon(mu_w);     % set time when person will get to their destination
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
            if walking == 0
                t_walking = inf;
            end
            
            
        case 4 % ride 1 finishes
            %%% HERE, WE ARE ALSO GONNA HAVE TO SET FANCY WALKING TIME LIKE
            %%% ABOVE %%%
            
        case 5 % ride 2 finishes
            %%% HERE, WE ARE ALSO GONNA HAVE TO SET FANCY WALKING TIME LIKE
            %%% ABOVE %%%
    end
end

% Analysis

% Returns a positive random number chosen from an exponential distribution
% with mean value 'mean'.
function e = expon(mean)
    e = -log(rand)*mean;
end

% Takes a number and adds or subtracts a random value from it given an
% upper bound offset. Returns num, give or take a number in range 0 to offset.
function t = give_or_take(num, offset)
    positive = randi([0 1]); % gets random int between 0 and 1
    value = num + rand() * offset;
    if positive
        t = value;
    else
        t = value * -1;
    end
end