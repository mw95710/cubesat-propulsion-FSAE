%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%                   By: Michael Wang, Cornell University                  %
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
% Assumptions: Isentropic flow, calorically perfect gas, steady state. Even
% though the pulse is highly transient, 90 percent of the thrurst comes
% from mid pulse "steady state" condition. The goal is to optimize mid
% pulse flow assuming ideal, steady state flow. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

T0 = 3000; % Kelvin
P0 = 10*101325; % Pa
gamma = 1.33; % specifc heat ratio of water vapor
MM = 0.018015; % molar mass of water vapor [kg/mol]
At = 1; % throat area
Ae = 1; % exit area
M = 1:0.01:10; % Mach number of divergent section
R = 8.3144/MM; % gas constant for water vapor

Ar = []; Pr = [];
for Ma = M
    % Expansion Ratio: Ae/At
    Artemp = (((2 + (gamma-1)*Ma^2)/(gamma+1))^((gamma+1)/(2*gamma - 2)))/Ma;
    Ar = [Ar Artemp];
    if Ma == 4.25
        Araccep = Artemp;
    end
    
    % Pressure ratio: Pe/P0
    Pr = [Pr (1 + ((gamma-1)/2)*Ma^2)^(gamma/(1-gamma))];
end

C_T = [];
% Coefficient of Thrust = Thrust/At*P0. It is directly proportional to 
% specific impulse given stagnation conditions and throat area
n = (2*gamma^2)/(gamma-1); % break down equation 
m = (2/(gamma+1))^((gamma+1)/(gamma-1));
Pa = 0;
for Ma = M
    C_T = [C_T sqrt(n*m*(1 - ((1 + ((gamma-1)/2)*Ma^2)^(gamma/(1-gamma)))^((gamma-1)/gamma)))...
        + (((1 + ((gamma-1)/2)*Ma^2)^(gamma/(1-gamma))) - Pa/P0)*...
        ((((2 + (gamma-1)*Ma^2)/(gamma+1))^((gamma+1)/(2*gamma - 2)))/Ma)];
end

IdealCT = 1.91; % Ideal Coefficient of Thrust given our configuration
AcceptableCT = 0.90*IdealCT;
% 90 percent of Maximum Coefficient of Thrust @ ~4.25 Mach

        
figure(1); clf;
subplot(2,1,1);
plot(M,Ar,'k-');
ylabel('Expansion Ratio A/At');
xlabel('Mach Number');
subplot(2,1,2);
plot(M,Pr,'r-');
ylabel('Pressure Ratio Pe/P0');
xlabel('Mach Number');

figure(2);
plot(M,C_T,'b-',[1,10],[AcceptableCT,AcceptableCT],'r-');
title('Coefficient of Thrust vs. Mach Number');
l = legend('Coefficient of Thrust (CoT)','Acceptable CoT (90%)');
set(l,'Location','northwest')
xlabel('Mach Number');
ylabel('Coefficient of Thrust');


