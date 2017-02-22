function [ SNR_vector, tn_vector, reduit_x_vector, reduit_azim_vector, reduit_elev_vector ] = filtre( x_vector,y_vector,elev_vector,azim_vector,fil_az_min,fil_az_max,fil_el_max,fil_el_min )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%% ELIMINAR LES MOSTRES AMB NAN's
reduit_x_vector=  x_vector(isnan(y_vector) == 0); %em quedo amb el tram després d'eliminar les mostres d'aquest tram sense dades
reduit_y_vector= y_vector(isnan(y_vector) == 0);
reduit_elev_vector=  elev_vector(isnan(y_vector) == 0);
reduit_azim_vector= azim_vector(isnan(y_vector) == 0);
%% APROXIMACIÓ POLINÒMICA PER A TREURE LA MITJA AL MEU SNR (FER-LO DE MITJA 0) I TAMBÉ CREO EL VECTOR TN_VECTOR --> SIND(VECTOR ELEVACIO)
r= polyfit(reduit_x_vector,reduit_y_vector,6);%faig l'aproximació polinòmica de grau 6 del tram
f1 = polyval(r,reduit_x_vector);
reduit_y1= reduit_y_vector- f1; % em quedo amb la diferencia entre el real i l'aproximació polinòmica per treure-li la mitja
SNR_vector= reduit_y1 - mean(reduit_y1); %li torno a treure la mitja per si encara no era diferent de 0
tn_vector= sind(reduit_elev_vector); %creo el meu vector sind(elevacio)

%% FILTRE AZIMUTH
reduit_azim_vector= wrapTo360(reduit_azim_vector);
% fil_az_min=130;fil_az_max=215;
SNR_vector(reduit_azim_vector <fil_az_min | reduit_azim_vector >fil_az_max )=[]; %filtre d'azimuth, nomès em quedo amb interval (60,300) --> per el cas de MAL crec que es lo més adequat
tn_vector(reduit_azim_vector <fil_az_min | reduit_azim_vector >fil_az_max )=[];
reduit_x_vector(reduit_azim_vector <fil_az_min | reduit_azim_vector >fil_az_max )=[];
reduit_elev_vector(reduit_azim_vector <fil_az_min | reduit_azim_vector >fil_az_max )=[];
reduit_azim_vector(reduit_azim_vector <fil_az_min | reduit_azim_vector >fil_az_max )=[];
%% FILTRE ELEVACIÓ
SNR_vector( reduit_elev_vector > fil_el_max | reduit_elev_vector < fil_el_min )=[]; %filtre d'elevacio, nomès em quedo amb interval mes petit de 45º
tn_vector(reduit_elev_vector > fil_el_max | reduit_elev_vector < fil_el_min )=[];
reduit_x_vector(reduit_elev_vector > fil_el_max | reduit_elev_vector < fil_el_min )=[];
reduit_azim_vector(reduit_elev_vector > fil_el_max | reduit_elev_vector < fil_el_min )=[];
reduit_elev_vector(reduit_elev_vector > fil_el_max | reduit_elev_vector < fil_el_min )=[];

end

