%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
%                   By: Michael Wang, Cornell University                  %
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~%
% this program uses the Rao maximum thrust nozzle contour approximation
% method to solve for the geometry of the contour given the throat radius
% and, desired expamsion ratio, and length. This script is verified with
% results from Rocket Propulsion Elements by Sutton. 

Rt = 0.795e-3; % throat radius [m]
R1 = Rt*1.5;
R2 = Rt*0.382;

e = 25; % area expansion ratio
f = 0.8; % percent of length of conical nozzle with half angle of 15 degrees
thetaN = (pi/180)*30; % angle at start of parabola
thetaE = (pi/180)*8.5; % angle at end of parabola
alpha = linspace(0,thetaN,1000);
L = (f*Rt/tan(15*pi/180))*(sqrt(e) - 1 + 1.5*(1/cos(15*pi/180) - 1)); % length of nozzle

% starting coordinates of parabola
xN = R2*sin(thetaN);
yN = Rt + R2*(1 - cos(thetaN));

ye = sqrt(e)*Rt - yN;
xe = L - xN;

syms S T

[S, T] = solve(tan(thetaE) - tan(thetaN) - S/(2*sqrt(S*xe + T)) + S/(2*sqrt(T)) == 0,...
    tan(thetaE) - ye/xe - sqrt(T)/xe + sqrt(S*xe + T)/xe - S/(2*sqrt(S*xe + T)) == 0);
Q = -sqrt(T);
P = tan(thetaN) - S/(2*sqrt(T));

x = linspace(0,xe,1000);
y = P.*x + Q + (S.*x + T).^0.5;

xx = x + xN;
yy = y + yN;
y1 = Rt + R2.*(1 - cos(alpha));
x1 = R2.*sin(alpha);
beta = linspace(-thetaN,0,1000);
x2 = R1.*sin(beta);
y2 = Rt + R1.*(1 - cos(beta));

Y = [y2 y1 yy];
X = [x2 x1 xx];

figure(1); clf;
plot(X,Y,'k-',X,-Y,'k-'); grid on;
title('Nozzle Contour');
xlabel('X [m]'); ylabel('Y [m]');




