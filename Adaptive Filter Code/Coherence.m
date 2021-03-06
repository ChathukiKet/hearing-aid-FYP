function [enhanced_ouput]=Coherence(x1,x2,fs)
% x1 , x2 : Input signals
% fs : Sampling Frequency

frameLength=floor(20*fs/1000);  
if (frameLength/2 ~= floor(frameLength/2))
      frameLength=frameLength+1;
end

Shift=floor(frameLength* 0.25);
window=hanning(frameLength);
FFT_LEN=2^nextpow2(frameLength);
  
lambda_x=0.68;   %Forgetting factor for smoothing power spectrum 
epsilon=10^-12;
   
lenS=min(length(x1),length(x2));
nFrame=0;
iniFrameSample=1;
endFrameSample=iniFrameSample+frameLength-1;
enhanced_ouput=zeros(lenS,1);

%Defining bands  
band1=floor(1000*FFT_LEN/fs);  %0 -> 1 KHz

%Defining exponents of coherence function
P=zeros(FFT_LEN/2,1);
P(1:band1)=16;
P(band1+1:FFT_LEN/2)=2;

    
%Defining threshholds for imaganary parts to consider negative (noise)
limNeg=zeros(FFT_LEN/2,1);
limNeg(1:band1)=-0.1;
limNeg(band1+1:FFT_LEN/2)=-0.3;

%Constant value of filter when imag part is negative
negImag_ConsFilter=0.05;
    
while endFrameSample<lenS

    nFrame=nFrame+1;

    %Get short-time magnitude and phase spectrums for each input channel
    Frame1=x1(iniFrameSample:endFrameSample);
    Frame2=x2(iniFrameSample:endFrameSample);

    wFrame1=Frame1 .* window;
    wFrame2=Frame2 .* window;

    X1=fft_new(wFrame1,FFT_LEN);
    X1=X1';
    X2=fft_new(wFrame2,FFT_LEN);
    X2=X2';

    if (nFrame==1)
        PX1X1=abs(X1).^2;
        PX2X2=abs(X2).^2;
        PX1X2=X1.*conj(X2); 
    else
        PX1X1=lambda_x.*PX1X1+(1-lambda_x).*abs(X1).^2;
        PX2X2=lambda_x.*PX2X2+(1-lambda_x).*abs(X2).^2;
        PX1X2=lambda_x.*PX1X2+(1-lambda_x).*X1.*conj(X2);
    end

     cohX=PX1X2 ./ sqrt(PX1X1.*PX2X2+epsilon); 
     reCOH=real(cohX(2:FFT_LEN/2+1));
     imCOH=imag(cohX(2:FFT_LEN/2+1));

    G1=1-abs(reCOH).^P;   %for suppressing noise coming from angles about 90

    G2=ones(FFT_LEN/2,1);               %for suppressing noise coming from angles greater than 90
    ind_neg= imCOH(1:FFT_LEN/2) < limNeg; 
    G2(ind_neg)=negImag_ConsFilter;                      

    G=G1.*G2;                            %Halfband final filter   
    H=abs([G ;flipud(G)]);    %Fullband final filter 

     %IFFT and OLA
     enhSpeech_Frame_tmp=real(ifft_new( H .* X1,FFT_LEN)); 
     enhSpeech_Frame_tmp=enhSpeech_Frame_tmp';
     enhSpeech_Frame=enhSpeech_Frame_tmp(1:frameLength);
     enhanced_ouput(iniFrameSample:endFrameSample)=enhSpeech_Frame + enhanced_ouput(iniFrameSample:endFrameSample);       

    %Update frame boundaries
    iniFrameSample=iniFrameSample+Shift;
    endFrameSample=endFrameSample+Shift;
end




