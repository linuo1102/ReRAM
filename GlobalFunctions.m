/*
 * GlobalFunctions.m
 * Global functions
 *
 * Created by Miguel Lastras on Feb 24, 2015
 */

#import "GlobalFunctions.h"

@implementation GlobalFunctions

+ (unsigned long int) log2floor:(unsigned long int)n
{
  unsigned long int c = 0;
  while(n){
    n = n >> 1;
    c++;
  }
  return c-1UL;
}

+ (void) write:(unsigned long int*)array 
        ofSize:(unsigned long int)size
        toFile:(NSString*)filePath
        binary:(BOOL)isBinary
{
  FILE *pFile;
  if(isBinary)
    pFile = fopen([filePath UTF8String], "wb");
  else
    pFile = fopen([filePath UTF8String], "w");
  if( pFile != NULL ){
    for(unsigned long int i = 0; i<size; i++){
      unsigned long int value = array[i];
      if(isBinary)
        fwrite(&value, sizeof(value), 1, pFile);
      else
        fprintf(pFile, "%lu\n", value);
    }
  }
  fclose(pFile);
}

// OLD MODELS, DO NOT USE
+ (double) normalizedReadEnergySavingsWithS:(double)S R:(double)R CC:(double)CC r:(double)r m:(double)m p:(double)p n:(double)n h:(double)h
{
  return (2*(1 + n)*(1 + p*(-1 + r)))/(2*CC*(-1 + h)*(-1 + p)*(2 + n*(1 + m*p*(-1 + r))) + 4*p*(m*n*(-1 + r) + r) + p*(n*(1 + m*p*(-1 + r)) + 2*r)*R + (n*(1 + m*p*(-1 + r)) + 2*p*(-1 + r))*S + 2*(2 + 2*n - 2*p + S) + h*(-(n*(1 + m*p*(-1 + r))*(2 + p*R + S)) - 2*(1 + S + p*(-1 + r + r*R + (-1 + r)*S))));
}
+ (double) normalizedReadEnergyWithS:(double)S R:(double)R CC:(double)CC e:(double)e r:(double)r m:(double)m p:(double)p n:(double)n h:(double)h
{
  return (e*(2*CC*(-1 + h)*(-1 + p)*(2 + n*(1 + m*p*(-1 + r))) + 4*p*(m*n*(-1 + r) + r) + p*(n*(1 + m*p*(-1 + r)) + 2*r)*R + (n*(1 + m*p*(-1 + r)) + 2*p*(-1 + r))*S + 2*(2 + 2*n - 2*p + S) + h*(-(n*(1 + m*p*(-1 + r))*(2 + p*R + S)) - 2*(1 + S + p*(-1 + r + r*R + (-1 + r)*S)))))/(2*r);
}
/////////////////////////

// THE SIX ENERGIES:
+ (double) M_readEnergyWithP:(double)p r:(double)r np:(double)np e:(double)e
{
  return (e*(1 + np)*(1 + p*(-1 + r)))/r;
}
+ (double) M_writeEnergyWithP:(double)p r:(double)r np:(double)np e:(double)e S:(double)S R:(double)R
{
  return -(e*(2 + np)*(1 + p*(-1 + r))*((-1 + p)*R - p*S))/(2*r);
}
+ (double) C_readEnergyWithP:(double)p r:(double)r np:(double)np e:(double)e S:(double)S R:(double)R
{
  return (e*(np*(2 + p*R + S) + 2*(1 + p*(-1 + r + r*R) + S)))/(2*r);
}
+ (double) C_writeEnergyWithP:(double)p r:(double)r np:(double)np e:(double)e CC:(double)CC
{
  return (CC*e*(2 + np))/(2*r);
}
+ (double) H_readEnergyWithP:(double)p r:(double)r np:(double)np e:(double)e S:(double)S CC:(double)CC m:(double)m h:(double)h
{
  return (e*(CC*(-1 + h)*(-1 + p)*(2 + np*(1 + m*p*(-1 + r))) - np*(1 + m*p*(-1 + r))*(-2 + (-1 + h)*S) + 2*(1 + p*(-1 + r) + S - h*S)))/(2*r);
}
+ (double) h_writeEnergyWithP:(double)p r:(double)r np:(double)np e:(double)e S:(double)S R:(double)R CC:(double)CC m:(double)m h:(double)h
{
  return -(e*(CC*(-1 + h)*(2 + np*(1 + m*p*(-1 + r))) + h*(-1 + p)*(2 + np*(1 + m*p*(-1 + r)) + 2*p*(-1 + r))*R - p*(2 + np*(1 + m*p*(-1 + r)) + 2*h*p*(-1 + r))*S))/(2*r);
}

// TOTAL ENERGIES:
+ (double) M_totalEnergyWithW:(double)w p:(double)p r:(double)r np:(double)np e:(double)e S:(double)S R:(double)R
{
  return -(e*(1 + p*(-1 + r))*(-2*(1 + np) + (2 + 2*(-1 + p)*R - 2*p*S + np*(2 + (-1 + p)*R - p*S))*w))/(2*r);
}
+ (double) C_totalEnergyWithW:(double)w p:(double)p r:(double)r np:(double)np e:(double)e S:(double)S R:(double)R CC:(double)CC
{
  return (e*(2*(1 + S - p*(-1 + r + r*R)*(-1 + w) + (-1 + CC - S)*w) + np*(2 + p*R + S - (2 - CC + p*R + S)*w)))/(2*r);
}
+ (double) H_totalEnergyWithW:(double)w p:(double)p r:(double)r np:(double)np e:(double)e S:(double)S R:(double)R CC:(double)CC m:(double)m h:(double)h
{
  return -(e*(CC*(-1 + h)*(2 + np*(1 + m*p*(-1 + r)))*(1 + p*(-1 + w)) - np*(1 + m*p*(-1 + r))*(2 + S - h*S + (-2 + h*R - h*p*R + (-1 + h + p)*S)*w) + 2*(-1 + p - p*r - S + h*S - (-((1 + p*(-1 + r))*(1 + h*(-1 + p)*R)) + (-1 + p + h*(1 + p*p*(-1 + r)))*S)*w)))/(2*r);
}

// DEACTIVATION ENERGY
+ (double) deactivationEnergyWithP:(double)p r:(double)r np:(double)np e:(double)e R:(double)R CC:(double)CC m:(double)m
{
  return (e*(2 - 2*p - CC*(-1 + p)*(2 + np*(1 + m*p*(-1 + r))) + 2*p*r*(1 + R) + np*(1 + m*p*(-1 + r))*(2 + p*R)))/(2*r);
}

@end
