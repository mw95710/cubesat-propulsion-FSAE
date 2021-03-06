%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%                   By: Michael Wang, Cornell University                  %
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
% This script simulates the transient mass flow through an orifice in a pulsed thruster. 
% It assumes no heat transfer through the combustion chamber walls. Combustion
% is modeled as constant pressure heat addition into H2 and O2. This script
% also explores how Thrust and Isp varies with respect to area ratio,
% pre-combustion pressure, throat area, and combustion chamber volume. This
% script will attempt to perform a multi-variable optimization to find maximum
% total Impulse (equivalent to maximum total Thrust) and Isp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function combfuel()
% compute Adiabatic Flame temperature and mole fraction of water after each
% burn
[MfracH2O, Tf, MWf] = combustionEquil();

% compute mL of water remaining in the chamber after n number of burns
nn = 1000; 
P0 = 1.01325e+6; % [Pa] or 10 atm
V = 0.0002; % [m^3] or around 0.25 U
VH2O = waterRemain(P0,V,Tf,MfracH2O,nn);
fprintf('The amount of water remaining in the chamber \n after %f burns = %f mL\n',nn,VH2O);
Me = 4.20427; % exit mach number
Rt = 0.795e-3; % throat radius

t = 0.00001; tfinal = 2; % in seconds 


%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
% % Optimization #1: Varying Throat Radius 
ImpulseRt = []; TRt = []; IspavgRt = []; ThrustavgRt = [];
Rt = linspace(1e-4,5e-3,100); % Varying Throat Radius
V = 2.1e-4; 

for tempRt = Rt
    [Th, Ispavg, Impulse, Thrustavg, Ar, c] = thrustCalc(Me, Tf, P0, V, ...
        tempRt, MWf, t, tfinal);
    ImpulseRt = [ImpulseRt, Impulse];
    IspavgRt = [IspavgRt, Ispavg];
    ThrustavgRt = [ThrustavgRt, Thrustavg];
end

[maxImpulseI, IndI] = max(ImpulseRt);
Rtmax = Rt(IndI);

figure(2);
%subplot(2,1,1);  
plot(Rt,ImpulseRt,'k-',Rtmax,maxImpulseI,'ro','LineWidth',1.8,'MarkerSize',13); 
grid on; box on;
Rtmax
title('Impulse vs. Throat Radius'); xlabel('Throat Radius [m]');
ylabel('Impulse [kg*m/s]');
legend('Range','Maximum','Location','Best');
set(gca,'FontSize',24);

figure(3);
%subplot(2,1,2);
plot(Rt,IspavgRt,'k-'); grid on;
title('Isp vs. Throat Radius'); xlabel('Throat Radius [m]');
ylabel('Isp [s]');
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
% % Optimization #2: Varying Combustion Chamber Volume
% ImpulseV = []; TV = []; IspavgV = []; ThrustavgV = [];
% % 1U = 1000 cm^3 = 0.001 m^3
% V = linspace(0.000001,0.003,100); % combustion chamber volume [m^3]
% Vc = (V.^(1/3) + 2*(0.003)).^3 - V; % Volume of the chamber shell [m^3]
% Mc = 4500.*Vc; % Mass of the chamber [kg] in Titanium
% 
% Me = 4.20427; P0 = 1.013e+5; Rt = 0.795e-3; % make other variables constant
% 
% % Note: V is only affected by Rt. Increase in Rt will cause increase in Vmax
% 
% for tempV = V
%     [Th, Ispavg, Impulse, Thrustavg, Ar, c] = thrustCalc(Me, Tf, P0, ...
%         tempV, Rt, MWf, t, tfinal);
%      ImpulseV = [ImpulseV, Impulse];
%      IspavgV = [IspavgV, Ispavg];
%      ThrustavgV = [ThrustavgV, Thrustavg];
% end
% 
% [maxImpulseV, IndV] = max(ImpulseV./Mc);
% Vmax = V(IndV);
% 
% figure(3);
% subplot(3,1,1); 
% plot(V,ImpulseV./Mc,'k-',Vmax,maxImpulseV,'ro'); grid on;
% title('Impulse vs. Combustion Chamber Volume'); 
% xlabel('Combustion Chamber Volume [m^3]'); ylabel('Impulse [kg*m/s]');
% legend('Range','Maximum');
% 
% subplot(3,1,2);
% plot(V,IspavgV,'k-'); grid on;
% title('Isp vs. Combustion Chamber Volume'); 
% xlabel('Combustion Chamber Volume [m^3]'); ylabel('Isp [s]');
%  
% subplot(3,1,3);
% plot(V,ThrustavgV,'k-'); grid on;
% title('Average Thrust vs. Combustion Chamber Volume'); 
% xlabel('Combustion Chamber Volume [m^3]'); ylabel('Average Thrust [N]');
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%

%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
% Optimization #3: Multi-Variable Optimization 
% Rt = linspace(1e-5,5.8e-3,25); % Throat Radius [m]
% V = linspace(0.0001,0.01,25); % combustion chamber volume [m^3]
% P0 = linspace(1.013e+5,1.013e+7,10); % Pre-combustion chamber pressure [Pa]
% Me = linspace(4.20427,4.20427,10); % Exit Mach Number (determines Area Ratio)
% 
% maxImp = 0; maxIsp = 0; 
% varsImp = []; % [Rt V P0 Me Ar]
% varsIsp = []; % [Rt V P0 Me Ar]
% impulse_op = [];
% Isp_op = [];
% Isp_actual = [];
% 
% opPress = 1.013e+6; % operating pressure of 10 atm
% 
% % for a = Me
%     for b = V
%          %for c = P0
%             impulse_optemp = [];
%             Isp_optemp = [];
%             Isp_actualtemp = [];
%             for d = Rt
%                 [Th, Ispavg, Impulse, Thrustavg, Ar, cc] = thrustCalc(4.20427, ...
%                     Tf, opPress, b, d, MWf, t, tfinal);
%                 Vc = (b^(1/3) + 2*(0.003))^3 - b; % Volume of the chamber shell [m^3]
%                 Mc = 4500*Vc; % Mass of the chamber [kg] in Titanium
%                 
%                 EffImpulse = Impulse;
%                 EffIspavg = Ispavg;
%                 propMass = propellantMass(b,opPress);
%                 
%                 impulse_optemp = [impulse_optemp, Impulse];
%                 Isp_optemp = [Isp_optemp, Ispavg];
%                 Isp_actualtemp = [Isp_actualtemp, Impulse/(propMass*9.81)];
%                 
%                 if EffImpulse > maxImp
%                     maxImp = EffImpulse;
%                     currentImp = Impulse;
%                     varsImp = [b d Ar];
%                 end
%                 
%                 if EffIspavg > maxIsp
%                     maxIsp = EffIspavg;
%                     currentIspavg = Ispavg;
%                     varsIsp = [b d Ar];
%                 end
%             end
%             impulse_op = [impulse_op; impulse_optemp];
%             Isp_op = [Isp_op; Isp_optemp];
%             Isp_actual = [Isp_actual; Isp_actualtemp];
%          %end
%     end
% % end
% 
% figure(4);
% surf(Rt, V, impulse_op);
% title('Impulse vs. Chamber Volume and Throat Radius');
% xlabel('Throat Radius [m]');
% ylabel('Combustion Chamber Volume [m^3]');
% zlabel('Impulse [N*s]');
% set(gca, 'FontSize', 15);
% 
% figure(5);
% surf(Rt, V, Isp_op);
% title('Theoretical Isp vs. Chamber Volume and Throat Radius');
% xlabel('Throat Radius [m]');
% ylabel('Combustion Chamber Volume [m^3]');
% zlabel('Specific Impulse [s]');
% set(gca, 'FontSize', 15);
% 
% figure(6);
% surf(Rt, V, Isp_actual);
% title('Actual Isp vs. Chamber Volume and Throat Radius');
% xlabel('Throat Radius [m]');
% ylabel('Combustion Chamber Volume [m^3]');
% zlabel('Specific Impulse [s]');
% set(gca, 'FontSize', 15);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function estimates the amount of water remaining inside the
% combustion chamber after n number of burns. The check valve closes when
% the pressure reaches back to 10 atm (same as pre-combustion pressure).
% Assume velocity of air is zero inside the chamber and temperature stays
% constant. This is an underestimate because temperature should decrease
% from the maximum flame temperature and product specieis (H, O, OH) would
% recombine to form more water as temperature decreases. Approximate gases
% as ideal for simplification. 
function VH2O = waterRemain(P,V,Tf,MfracH2O,n)
ntot = P*V/(8.314*Tf); % total moles after each burn
nH2O = MfracH2O*ntot*n; % moles of H2O after n number of burns

% mL of water remaining after n number of burns based on density of water
% at room temperature. 
VH2O = nH2O*18.01528/0.9982; % mL of water remaining after 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function calculates and plots adiabatic flame temperature and total
% molecular weight of products. Combustion is modeled as a constant-pressure 
% heat addition process. Equilibrium calculation is done through an online 
% calculator from Colorado State. 
function [MfracH2O, Tf, MWf] = combustionEquil()
n = [1/20, 1/8, 1/4, 1/2, 5/8, 7/8, 1]; % oxidant to fuel mol ratio
m = 16.*n; % oxidant to fuel mass ratio 
mi = linspace(0,16,1000); % interpolation 

% equilibrium temperature from Colorado State Chemical Equilibrium Calculator
T = [1.0965e3, 2.0653e+03, 3.1199e+03, 3.6347e+03, 3.5815e+03, 3.3958e+03...
    , 3.2997e+03]; 
Ti = interp1(m,T,mi,'spline'); % interpolation 

% molecular weight g/mol [O2 H2 H2O O H OH]
MW = [15.99*2; 1.008*2; 18.02; 15.99; 1.008; 16.998]; 

% mole fractions of species at various mass ratios. Data is from Colorado
% State Chemical Equilibrium Calculator 
Mfrac = [3.5694e-22, 9.0000e-01, 1.0000e-01, 6.0725e-21, 3.2106e-09, 1.6098e-12;...
    4.8176e-10, 7.4973e-01, 2.4995e-01, 3.3644e-09, 3.0696e-04, 1.1722e-05;
    8.8914e-05, 4.8566e-01, 4.8361e-01, 2.2377e-04, 2.2195e-02, 8.2231e-03;
    3.8404e-02, 1.2874e-01, 6.6745e-01, 1.8929e-02, 4.0229e-02, 1.0624e-01;
    9.7725e-02, 7.0046e-02, 6.5619e-01, 2.6612e-02, 2.6492e-02, 1.2293e-01;
    2.3193e-01, 2.5986e-02, 5.9765e-01, 2.5561e-02, 1.0562e-02, 1.0831e-01;
    2.9272e-01, 1.6893e-02, 5.6697e-01, 2.2025e-02, 6.7132e-03, 9.4674e-02]; 

MfracH2O = Mfrac(4,3);
Tf = T(4);

MW1 = Mfrac*MW; % total molecular weight (used to calculate specific thrust
MWi = interp1(m,MW1,mi,'spline'); % interpolation 
MWf = MW1(4);

% calculate specific thrust = Thrust/m_dot
SpT = sqrt(((2*1.4*8.314)./(0.4.*MW1')).*T.*(1 - (1/50)^((1.4-1)/1.4)));
SpTi = interp1(m,SpT,mi,'spline'); % interpolation 

% graph results
figure(1); clf;
subplot(2,1,1);
plot(m(4),T(4),'ro',mi,Ti,'k-'); grid on;
title('Adiabatic Flame Temperature');
xlabel('Oxidant-to-Fuel Mass Ratio'); 
ylabel('Adiabatic Flame Temperature [K]');
legend('Stoichiometry','Interpolation','Location','SouthEast');

subplot(2,1,2); 
plot(m(4),MW1(4), 'ro',mi,MWi,'k-'); grid on;
title('Post Flame Molecular Weight');
xlabel('Oxidant-to-Fuel Mass Ratio'); 
ylabel('Post Flame Molecular Weight [g/mol]');
legend('Stoichiometry','Interpolation','Location','SouthEast');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function calculates the transient thrust generated by the combustion
% chamber given an initial total combustion chamber pressure and
% temperature. This assumes isentropic expansion through a nozzle of given
% area ratio Ar. The process is modeled as Quasi-1D. This does not account
% for the initial transient period when mdot increases from 0 to a maximum
% value. According to Guille's paper, this transient period is very short
% compared to the pulse width. Therefore, it does not contribute much to
% the thrust. 
function [T, Ispavg, Impulse, Thrustavg, Ar, count] = thrustCalc(Me, T0, P0, V, Rt,...
    MW, t, tfinal)
% http://www.thespacerace.com/forum/index.php?topic=2583.0
% specific heat ratio. Data from LOX and LH2 rockets
gamma = 1.26; 
Astar = pi*Rt^2;
R = 8.314/(MW/1000);
mdot = []; P02 = P0; Pnew = P0;
rho0 = P0/(R*T0); M0 = rho0*V; Mnew = M0;
const = sqrt(gamma*(2/(gamma+1))^((gamma+1)/(gamma-1)));

time = 0:t:tfinal;

kb = 1.3806504e-23; % Boltzmann constant [J/K]
Temperature = T0; % flame temperature [K]
hd = 265e-12; % kinetic diameter of H2O [m]
L = V^(1/3); % physical length scale, approximated as cube root of volume [m]

% For each time step, calculate mass flow rate and corresponding pressure
% drop 
count = [];
for i = time
    mdotnew = Astar*Pnew*const/(sqrt(R*T0));
    mdot = [mdot mdotnew];
    Mnew = Mnew - mdotnew*t;
    rhonew = Mnew/V;
    Pnew = rhonew*R*T0;
    P02 = [P02 Pnew];
    
    % calculate the knudsen number to determine if fluid is a continuum or
    % rarified. Stop loop when the fluid becomes rarified because the
    % continuum compressible equations will not apply. 
    kn = kb*Temperature/(sqrt(2)*pi*(hd^2)*Pnew*L);
    
    if kn > 1
        break
    end
    
    if Mnew < 0
        break
    end
end

P02 = P02(1:(end-1));

% Area-Mach Relation
Ar = (((2 + (gamma-1).*Me.^2)./(gamma+1)).^((gamma+1)/(2*gamma - 2)))./Me;
Te = T0/(1 + (gamma-1)*(Me^2)/2); % exhaust temperature 
Pe = P02./((1 + (gamma-1)*(Me^2)/2)^(gamma/(gamma-1))); % exit pressure
% exit velocity at each time step
ue = sqrt((2*gamma*R*T0/(gamma-1)).*(1 - (Pe./P02).^((gamma-1)/gamma)));
Ae = Ar.*Astar; % exit area
T = mdot.*ue + Pe.*Ae; % Thrust at each time step
ueq = T./mdot; % equivalent exhaust velocity 
g = 9.81; % [m/s^2]
Isp = ueq./g; % specific impulse at each timestep 
Ispavg = sum(Isp)/length(Isp); % Average Specific Impulse 
Isp = fix(Isp.*10^7)/10^7; % Specific Impulse
% fprintf('Average Specific Impulse = %f seconds\n',Ispavg);
Tl = length(T);
Impulse = trapz(time(1:Tl),T); % Calculates total impulse 
Thrustavg = Impulse/(tfinal-0); % Average Thrust across pulse

% figure(2);
% subplot(2,1,1);
% plot(time,mdot,'k-'); grid on;
% title('Mass Flow Rate vs. Time Elapsed');
% xlabel('Time [s]'); ylabel('Mass Flow Rate [kg/s]');
% 
% subplot(2,1,2);
% plot(time,P02,'k-'); grid on;
% title('Combustion Chamber Pressure vs. Time Elapsed');
% xlabel('Time [s]'); ylabel('Pressure [Pa]');
% 
% figure(3);
% subplot(2,1,1);
% plot(time,T,'k-'); grid on;
% title('Thrust vs. Time Elapsed');
% xlabel('Time [s]'); ylabel('Thrust [N]');
% 
% subplot(2,1,2);
% plot(time,Isp,'k-'); grid on;
% title('Specific Impulse vs. Time Elapsed');
% xlabel('Time [s]'); ylabel('Isp [s]');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculates propellant mass present before combustion based on
% stoichiometric ratio. P is the absolute pressure [Pa] and V is the chamber
% volume [m^3] 
function m = propellantMass(V,P)
% constants
R = 8.3144598; % gas constant [J/(K*mol)]
oxMM = 0.03199880; % molar mass of O2 [kg/mol]
fuMM = 0.00201588; % molar mass of H2 [kg/mol]
T = 293; % steady state temperature of combustion chamber [K]

% calculate precombustion ox partial pressure [Pa]
oxprepar = P/3;

% mols of O2 before combustion
prenox = oxprepar*V/(R*T);

oxMasscons = (prenox)*oxMM; % O2 consumed assuming all intial O2 is used [kg]
fuMasscons = 2*(prenox)*fuMM; % H2 consumed assuming all initial H2 is used [kg]

m = oxMasscons + fuMasscons; % conservative estimate 
end