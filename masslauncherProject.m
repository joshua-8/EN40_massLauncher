function masslauncherProject
close all;
clear all;
const=[9.8,.9652,3.175,.0454]; %g, maxHeight, maxMass, minLaunchedMass
tSpan=[0:.0001:1];

% mass, massHeight, springConstant, springHeight
DV=[[.05,.003175,423,.1016];
    [.38,.0254,3130.5,.127];
    [2.64,.0762,23393.9,.1016]];

findlaunchvel(DV,const,tSpan)

end

function vel=findlaunchvel(DV,const,tSpan)
    sizeArr=size(DV);
    w=zeros(sizeArr(1)*2,1);
    initialW=zeros(sizeArr(1)*2,1);
    for i=1:sizeArr(1)
       if(sizeArr(2)~=4)
         error("ERROR, incorrect length entry in DV")
       end
    end
    options=odeset('Event',@(t,w) event(t,w,DV));
    
    assemHeight=0;
    for i=sizeArr(1):-1:1 %set initial heights    
        assemHeight=assemHeight+(DV(i,2)+DV(i,4));
        initialW(i*2-1)=assemHeight;
    end
    
    initialVel=-sqrt(2*const(1)*(const(2)-assemHeight));
    for i=2:2:sizeArr(1)*2 %set initial velocities to speed at first contact
        initialW(i)=initialVel;
    end
    
    %[x1,v1,x2,v2,xn,vn]
    [times,sols]=ode45(@(t,w) diffeq(t,w,sizeArr(1),DV,const),tSpan,initialW,options);

    vel=max(sols(:,2));

end

%[v1,a1,v2,a2,vn,an]
function dwdt=diffeq(~,w,N,DV,const)
    g=const(1);
    dwdt=zeros(N*2,1);
    for i=1:N
        dwdt(i*2-1)=w(i*2); %set velocity in output to velocity in input
        if i==1
            Fnm1=0; %nothing pushes down on the top mass
        else
            Fnm1=(w(i*2-3)-w(i*2-1)-DV(i-1,2)-DV(i-1,4))*DV(i-1,3); %force from mass above
        end
        if i==N
            Fn=(w(i*2-1)-DV(i,2)-DV(i,4))*DV(i,3); %x(n+1)=0, the ground
        else
            Fn=(w(i*2-1)-w(i*2+1)-DV(i,2)-DV(i,4))*DV(i,3); %normal F calc
        end
        dwdt(i*2)=(Fnm1-Fn-DV(i,1)*g)/DV(i,1); %acceleration
    end
    
    
end

function [eventvalue,stopthecalc,eventdirection] = event(~,w,DV)
eventdirection=1;
stopthecalc=1;
eventvalue=w(1)-w(3)-DV(1,2)-DV(1,4); % x1-x2-mh1-sh2 (how much 1st spring stretched)
end 
