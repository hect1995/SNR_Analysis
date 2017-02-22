function spectograma_individual_millor_perimprimir(SNR_vector,f,tn_vector,reduit_azim_vector,reduit_elev_vector,reduit_x_vector,lambda,doy,tram,satelit,valor_auxiliar,fil_el_max,fil_el_min)

[~,ai,~]= unique(tn_vector);

SNR_vector= SNR_vector(ai);
tn_vector= tn_vector(ai);
reduit_elev_vector= reduit_elev_vector(ai);
reduit_azim_vector= reduit_azim_vector(ai);
reduit_x_vector= reduit_x_vector(ai);

%frequencies va de 3 a 7 --> prenc mesura cada 0.25 --> 16 posicions
altures= [3 3.125 3.25 3.375 3.5 3.675 3.75 3.875 4 4.125 4.25 4.375 4.5 4.675 4.75 4.875 5 5.125 5.25 5.375 5.5 5.675 5.75 5.875 6 6.125 6.25 6.375 6.5 6.675 6.75 6.875 7];
frequencies=(2/lambda).*altures;
representacio= zeros(length(altures)-1,15000);
reduit_elev_vector_taula=zeros(1,15000);
j=1;
i=1;
contador=1;
window= 500; %la finestra escollida
step= 30; %el step escollit per anar movent el spectograma
auxiliar= 1;
if contador+window  >length(SNR_vector) - 2*step %aixi m'asseguro de tenir suficients dades i no que nomes pugui agafar una subfinestra i que tot peti
    auxiliar =0;
end


while j~=0
    if contador+window - length(SNR_vector) <0
        Y= periodograma(2*pi*f,tn_vector(contador:contador+window),SNR_vector(contador:contador+window)); %el vector a secas (sense interpolar)
        
        for aux=1:length(representacio(:,1))
            frequencies_alta= frequencies(aux+1)*ones(1,length(f));
            frequencies_baixa= frequencies(aux)*ones(1,length(f));
            Y_tram= Y(f<frequencies_alta & f>=frequencies_baixa);
            representacio(aux,i)= mean(Y_tram);
        end
        reduit_elev_vector_taula(i)= reduit_elev_vector(contador+window);
        contador= contador + step ; %per on començar el seguent tram
        i=i+1; %contador per anar afegint subfinestres en representacio i reduit_elev_vector_taula
    else
        j= 0;
    end
end


representacio_final= zeros(length(altures)-1,i-1);
for ii=1:length(altures)-1
    representacio_final(ii,:)= representacio(ii,1:i-1) ;
end

if auxiliar ~= 0
    contador= 1;
    [~,I]= max(representacio_final(:));
    [~, I_col] = ind2sub(size(representacio_final),I); %per trobar la columna amb el maxim
    Y_maxim= periodograma(2*pi*f,tn_vector(contador+(I_col-1)*step:(contador+(I_col-1)*step)+window),SNR_vector(contador+(I_col-1)*step:(contador+(I_col-1)*step)+window)); %per recalcular el periodograma del màxim, segurament podria ser més eficient però bueno
    temps= mean(reduit_x_vector(contador+(I_col-1)*step:(contador+(I_col-1)*step)+window));
    azimuth= mean(reduit_azim_vector(contador+(I_col-1)*step:(contador+(I_col-1)*step)+window));
else
    Y_maxim= 0;
    temps= 0;
    azimuth= 0;
end

reduit_elev_vector_taula_final= reduit_elev_vector_taula(1:i-1);
if valor_auxiliar == 0 
    if reduit_elev_vector(1)>12
        reduit_azim_vector_512= reduit_azim_vector;
    else
     reduit_azim_vector_512= reduit_azim_vector(reduit_elev_vector<12 & reduit_elev_vector>fil_el_min);
    end
else
     reduit_azim_vector_512= reduit_azim_vector(reduit_elev_vector<fil_el_max);
end

if auxiliar~=0
    figure;
    pcolor(reduit_elev_vector_taula_final,altures(1:end-1),representacio_final)
    str = sprintf('Average Azimuth =%s',num2str(mean(reduit_azim_vector_512)));
    title(str);
    str1= sprintf('Starts in elevation = %s and finishes in elevation= %s',num2str(reduit_elev_vector(1)),num2str(reduit_elev_vector(end)));
    xlabel(str1)
    ylabel('Height [m]')
    ylim([altures(1) altures(end)])

    reduit_azim_vector_512_final= mean(reduit_azim_vector_512);
    filename= strcat('2_Bones_Image',doy,'_',num2str(satelit),'_',num2str(tram),'no_interpolat');

    if reduit_azim_vector_512_final < 20
        fname = '/Users/Hector/Desktop/RESULTATS_2/0-20';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 40 && reduit_azim_vector_512_final > 20
        fname = '/Users/Hector/Desktop/RESULTATS_2/20-40';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 60 && reduit_azim_vector_512_final > 40
        fname = '/Users/Hector/Desktop/RESULTATS_2/40-60';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 80 && reduit_azim_vector_512_final > 60
        fname = '/Users/Hector/Desktop/RESULTATS_2/60-80';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 100 && reduit_azim_vector_512_final > 80
        fname = '/Users/Hector/Desktop/RESULTATS_2/80-100';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 120 && reduit_azim_vector_512_final > 100
        fname = '/Users/Hector/Desktop/RESULTATS_2/100-120';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 140 && reduit_azim_vector_512_final > 120
        fname = '/Users/Hector/Desktop/RESULTATS_2/120-140';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 160 && reduit_azim_vector_512_final > 140
        fname = '/Users/Hector/Desktop/RESULTATS_2/140-160';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 180 && reduit_azim_vector_512_final > 160
        fname = '/Users/Hector/Desktop/RESULTATS_2/160-180';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 200 && reduit_azim_vector_512_final > 180
        fname = '/Users/Hector/Desktop/RESULTATS_2/180-200';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 220 && reduit_azim_vector_512_final > 200
        fname = '/Users/Hector/Desktop/RESULTATS_2/200-220';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 240 && reduit_azim_vector_512_final > 220
        fname = '/Users/Hector/Desktop/RESULTATS_2/220-240';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 260 && reduit_azim_vector_512_final > 240
        fname = '/Users/Hector/Desktop/RESULTATS_2/240-260';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 280 && reduit_azim_vector_512_final > 260
        fname = '/Users/Hector/Desktop/RESULTATS_2/260-280';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 300 && reduit_azim_vector_512_final > 280
        fname = '/Users/Hector/Desktop/RESULTATS_2/280-300';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 320 && reduit_azim_vector_512_final > 300
        fname = '/Users/Hector/Desktop/RESULTATS_2/300-320';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 340 && reduit_azim_vector_512_final > 320
        fname = '/Users/Hector/Desktop/RESULTATS_2/320-340';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    elseif reduit_azim_vector_512_final < 360 && reduit_azim_vector_512_final > 340
        fname = '/Users/Hector/Desktop/RESULTATS_2/340-360';
        saveas(gca, fullfile(fname, filename), 'jpeg');
    end
    
    close Figure 1
    

end