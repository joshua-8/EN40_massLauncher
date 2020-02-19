function processMassTestData
clear all;
close all;
data = csvread('mass_launcher_test_data2.csv');
sizeArr=size(data);
numMasses=sizeArr(2)-1;
time=data(:,1);
pos=zeros(sizeArr(1),numMasses);
for i=1:numMasses
    pos(:,i)=data(:,i+1); 
end
plot(time,pos);
title("position");
figure
vel=zeros(sizeArr(1)-1,numMasses);
for i=2:sizeArr(1)
    vel(i,:)=(pos(i,:)-pos(i-1,:))/(time(i)-time(i-1)); 
end
plot(time,vel);
title("velocity");
end

