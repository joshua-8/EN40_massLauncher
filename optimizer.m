function optimizer
clc
clear all;
close all;

syms m1 m2 m3 k1 k2 k3

% g, maxHeight
const = [9.8, 0.53]; %we changed the max height in order to prevent spring over-deflection
tSpan = [0, 1];

% mass height, spring height (for initial test, just use random heights)
heights = [[0.03, 0.08];
           [0.03, 0.08];
           [0.03, 0.08]];

% mass, spring constant
DV = [[m1, k1];
      [m2, k2];
      [m3, k3]];

guess = [[0.10, 423];
         [0.77, 700];
         [2, 1000]];

minvars = [[0.0499, 267.87];
           [0.0499, 267.87];
           [0.0499, 267.87]];

maxvars = [[2.649, 23393.92];
           [2.649, 23393.92]; 
           [2.649, 23393.92]];

A = []; b = []; C = []; d= [];

optimalvars = fmincon(@(DV) - findlaunchvel(DV, heights, const, tSpan, false), guess, A, b, C, d, minvars, maxvars)
optimalvel = findlaunchvel(optimalvars, heights, const, tSpan, true)

%our picked variables from tables of values

finalDV = [[0.0499, 267.870];
           [0.376, 2400.11];
           [2.649, 14839.959]];
       
finalheights = [[0.003175, 0.127];
                [0.0254, 0.1016];
                [0.0762, 0.1016]];
           
finalvel = findlaunchvel(finalDV, finalheights, const, tSpan, false)
end

function vel = findlaunchvel(DV, heights, const, tSpan, makePlot)
    sizeArr = size(DV);
    w = zeros(sizeArr(1) * 2, 1);
    initialW = zeros(sizeArr(1) * 2, 1);
    assemHeight = 0;
    for i = sizeArr(1):-1:1 %set initial heights
        assemHeight = assemHeight + (heights(i, 1) + heights(i, 2));
        initialW(i * 2 - 1) = assemHeight;
    end
    
    initialVel = -sqrt(2 * const(1) * (const(2) - assemHeight));
    for i = 2:2:sizeArr(1)*2 %set initial velocities to speed at first contact
        initialW(i) = initialVel;
    end
    
    options = odeset('Event', @(t,w) event(t, w, heights));
    
    %[x1,v1,x2,v2,xn,vn]
    [time, sols] = ode45(@(t,w) diffeq(t, w, sizeArr(1), heights, DV, const), tSpan, initialW, options);
    vel = max(sols(:, 2));
    if makePlot
        plot(time,sols(:,1:2:sizeArr(1)*2));
        title("position");
        figure;
        plot(time,sols(:, 2:2:sizeArr(1)*2));
        title("velocity");
        figure;
        hold on;
    for i=1:sizeArr(1) %for each spring, find spring displacement
        if i==sizeArr(1)
            plot(time,(sols(:,i*2-1)-heights(i,1)-heights(i,2))); %x(n+1)=0, the ground
        else
            plot(time,(sols(:,i*2-1)-sols(:,i*2+1)-heights(i,1)-heights(i,2))); %normal calc
        end
    end
    hold off;
    title("spring stretch");
    end
end

%[v1,a1,v2,a2,vn,an]
function dwdt=diffeq(~, w, N, heights, DV, const)
    g = const(1);
    dwdt = zeros(N*2,1);
    for i=1:N
        dwdt(i*2-1)=w(i*2); %set velocity in output to velocity in input
        if i==1
            Fnm1=0; %nothing pushes down on the top mass
        else
            Fnm1=(w(i*2-3)-w(i*2-1)-heights(i-1,1)-heights(i-1,2))*DV(i-1,2); %force from mass above
        end
        if i==N
            Fn=(w(i*2-1)-heights(i,1)-heights(i,2))*DV(i,2); %x(n+1)=0, the ground
        else
            Fn=(w(i*2-1)-w(i*2+1)-heights(i,1)-heights(i,2))*DV(i,2); %normal F calc
        end
        dwdt(i*2)=(Fnm1-Fn-DV(i,1)*g)/DV(i,1); %acceleration
    end
end

function [eventvalue,stopthecalc,eventdirection] = event(~,w,heights)
eventdirection=1;
stopthecalc=1;
eventvalue=w(1)-w(3)-heights(1,1)-heights(1,2); % x1-x2-mh1-sh2 (how much 1st spring stretched)
end 