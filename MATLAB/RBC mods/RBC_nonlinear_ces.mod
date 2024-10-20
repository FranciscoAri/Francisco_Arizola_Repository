%----------------------------------------------%
%-------------Variables Endógenas--------------%
%----------------------------------------------%
var Y C K L A R W I;

%----------------------------------------------%
%--------------Variables Exógenas--------------%
%----------------------------------------------%
varexo eps_A;

%----------------------------------------------%
%-----------------Parámetros-------------------%
%----------------------------------------------%
parameters alph betta delt gam pssi rhoA etaC etaL;

%----------------------------------------------%
%-----------Calibración de parámetros----------%
%----------------------------------------------%
alph = 0.35; betta = 0.99; delt = 0.025; gam = 1; pssi = 1.6; rhoA = 0.9;
etaC  = 2;   etaL  = 1.5;

%----------------------------------------------%
%-----------Planteamiento del Modelo-----------%
%----------------------------------------------%
model;
    #UC  = gam*C^(-etaC);
    #UCp = gam*C(+1)^(-etaC);
    #UL  = -pssi*(1-L)^(-etaL);
    UC = betta*UCp*(1-delt+R(+1));
    W = -UL/UC;
    K = (1-delt)*K(-1)+I;
    Y = I+C;
    Y = A*K(-1)^alph*L^(1-alph);
    W = (1-alph)*Y/L;
    R = alph*Y/K(-1);
    log(A) = rhoA*log(A(-1))+eps_A;
end;

%----------------------------------------------%
%-------------Estado Estacionario--------------%
%----------------------------------------------%
initval;
    A = 1;
    Y = 1;
    C = 0.8;
    K = 10;
    L = 0.3;
    R = 0.04;
    W = 0.7;
    I = 0.2;
end;

%----------------------------------------------%
%---------------Definir los shocks-------------%
%----------------------------------------------%
shocks;
    var eps_A = 0.01^2;  % Pequeño shock positivo en la productividad
end;

% Simula las respuestas al impulso con horizonte de 20 periodos
stoch_simul(order=1,irf=20);
