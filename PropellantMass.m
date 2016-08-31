function PropellantMass()
% This function calculates propellant mass consumed assuming ideal gas law,
% isothermal, and adiabatic conditions. This also assumes there is no
% post-combustion condensation (this problem should be studied further).
% Assumes combustion of stoichiometric, premixed mixture of H2 and O2.
% Thrust = mdot*Ve + (pe - p0)*Ae
% need to include boundary layer efficiency (affect area ratio). 

format long 

% constants
% V = pi*(0.03^2)*0.045 - pi*((0.037336/2)^2)*0.026912 + pi*((0.02231919/2)^2)*0.019812 %calculated from solidworks Michael [m^3]   
% V = 2.03457e-5; %calculated from solidworks Malkiel [m^3]
V = 5.9665*(0.0254^3); % Volume of chamber in use Kyle [m^3]
R = 8.3144598; % gas constant [J/(K*mol)]
oxMM = 0.03199880; % molar mass of O2 [kg/mol]
fuMM = 0.00201588; % molar mass of H2 [kg/mol]
g = 9.80665; % standard gravity constant of Earth [m/s^2]
Ae = pi*(0.03159456/2)^2; % nozzle exit area [m^2]
samplingRate = 1612.903225806452; % sampling rate of pressure sensor [count/s]

% input parameters
atm = 101325; % atmospheric pressure/back pressure [Pa]
precombP = 551581 + atm; % pre-combustion absolute pressure [Pa]
postcombP = 68947.6 + atm; % post-combustion absolute pressure [Pa]
T = 293; % steady state temperature of combustion chamber [K]
% check valve closes when chamber pressure is about 251.5953 psi and when
% temperature is about 2985 K
pulseDur = 17/samplingRate; % approximate pulse duration [s]
impulsecorr = pulseDur*atm*Ae; % impulse correction for back pressure [N*s]
impulsemeasured = 4.4687452e-2; % measured impulse from test rig [N*s]
impulse = impulsemeasured + impulsecorr; % impulse delivered [N*s]

% calculate precombustion ox partial pressure [Pa]
oxprepar = precombP/3;

% mols of O2 before combustion
prenox = oxprepar*V/(R*T);

% calculate postcombustion ox partial pressure [Pa[
oxpostpar = postcombP/3;

% mols of O2 after combustion
postnox = oxpostpar*V/(R*T);

% calculate masses of propellants
oxMass = (prenox - postnox)*oxMM; % O2 consumed [kg]
fuMass = 2*(prenox - postnox)*fuMM; % H2 consumed [kg]
oxMasscons = (prenox)*oxMM; % O2 consumed assuming all intial O2 is used [kg]
fuMasscons = 2*(prenox)*fuMM; % H2 consumed assuming all initial H2 is used [kg]
totMass = oxMass + fuMass; % total propellant mass consumed [kg]
totMasscons = oxMasscons + fuMasscons; % conservative estimate 

% calculate corrected vacuum specific Impulse = impulse/propellant weight [s]
format short
vacIsp = impulse/(totMass*g); % estimate
vacIspcons = impulse/(totMasscons*g); % conservative estimate
end