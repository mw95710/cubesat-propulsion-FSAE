% this script creates contour plots for helmholtz resonance effects in a
% 4-runner cylinder plenum intake manifold. Variables include runner length
% and plenum volume. This is used to size the intake manifold to our engine
% optimum rpm. 

RunLen = [];
PleVol = [];
freq1 = [];
freq2 = [];
f1 = [];
f2 = [];

n = 75; % number of elements

minRL = 4;
maxRL = 20;
minPV = 30.5119;
maxPV = 183.071; 
 

for RL = linspace(minRL, maxRL, n) % varying runner lengths in inches
    for PV = linspace(minPV, maxPV, n) % varying plenum volume from 0.5 L to 3L in cubic inches
        A = 6.469; % cross sectional area of of plenum 
        R = 12.2*(125/101); % compresion ratio weighted by manifold absolute pressure 
        c = 1267.014; % average speed of sound in ft/s in plenum at average temperature of 98 Celsius
        k = 2; % correction factor to convert resonance to engine rpm
        V = 9.153; % Displacement of one cylinder in cubic inches
        L1 = RL/1.474; % Inductance of inlet pipe in 1/inch 
        L2 = (PV/A)/A; % Inductance of the feeder pipe (plenum) in 1/inch 
        a = L2/L1; % Inductance ratio of feeder pipe to Inlet pipe
        V1 = (V/2)*((R+1)/(R-1)); % Volume of cylinder at mid stroke in cubic inches
        V2 = 3*(pi*RL*(1.37/2)^2); % Volume of the inlet idle pipes (3) in cubic inches 
        b = V2/V1; % Capacitance ratio 

       
        f1 = [f1 (162*c/k)*sqrt(((a*b+a+1) - sqrt((a*b+a+1)^2 - 4*a*b))/(2*a*b))*sqrt(1/(L1*V))*sqrt((R-1)/(R+1))]; % lower frequency in rpm
        f2 = [f2 (162*c/k)*sqrt(((a*b+a+1) + sqrt((a*b+a+1)^2 - 4*a*b))/(2*a*b))*sqrt(1/(L1*V))*sqrt((R-1)/(R+1))]; % highe frequency in rpm

    end

    freq1 = [freq1; f1];
    freq2 = [freq2; f2];
    f1 = [];
    f2 = [];

end

disp(f1)
disp(f2)

 

RunLen = linspace(minRL, maxRL, n);
PleVol = linspace(minPV, maxPV, n);

 
figure
hold on
[c1,h1] = contour(PleVol, RunLen, freq1);
clabel(c1,h1)
plot(71.7,11.8,'ro')
title('Tuned Engine RPM of the First Harmonic')
ylabel('Runner Length (in)')
xlabel('Plenum Volume (in^3)')
hold off

figure
hold on
[c1,h1] = contour(PleVol, RunLen, freq2);
clabel(c1,h1)
plot(71.7,11.8,'ro')
title('Tuned Engine RPM of the Second Harmonic')
ylabel('Runner Length (in)')
xlabel('Plenum Volume (in^3)')
hold off
