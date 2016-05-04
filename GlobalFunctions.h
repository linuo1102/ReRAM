/*
 * GlobalFunctions.h
 * Global functions
 * 
 * Created by Miguel Lastras on Feb 24, 2015
 */

#import <Foundation/Foundation.h>

#define BYTETOBINARYPATTERN "\
%d%d%d%d%d%d%d%d \
%d%d%d%d%d%d%d%d \
%d%d%d%d%d%d%d%d \
%d%d%d%d%d%d%d%d \
%d%d%d%d%d%d%d%d \
%d%d%d%d%d%d%d%d \
%d%d%d%d%d%d%d%d \
%d%d%d%d%d%d%d%d\n"
#define BYTETOBINARY(word)  \
  (word & 0x8000000000000000 ? 1 : 0), \
  (word & 0x4000000000000000 ? 1 : 0), \
  (word & 0x2000000000000000 ? 1 : 0), \
  (word & 0x1000000000000000 ? 1 : 0), \
  (word & 0x0800000000000000 ? 1 : 0), \
  (word & 0x0400000000000000 ? 1 : 0), \
  (word & 0x0200000000000000 ? 1 : 0), \
  (word & 0x0100000000000000 ? 1 : 0), \
  (word & 0x0080000000000000 ? 1 : 0), \
  (word & 0x0040000000000000 ? 1 : 0), \
  (word & 0x0020000000000000 ? 1 : 0), \
  (word & 0x0010000000000000 ? 1 : 0), \
  (word & 0x0008000000000000 ? 1 : 0), \
  (word & 0x0004000000000000 ? 1 : 0), \
  (word & 0x0002000000000000 ? 1 : 0), \
  (word & 0x0001000000000000 ? 1 : 0), \
  (word & 0x0000800000000000 ? 1 : 0), \
  (word & 0x0000400000000000 ? 1 : 0), \
  (word & 0x0000200000000000 ? 1 : 0), \
  (word & 0x0000100000000000 ? 1 : 0), \
  (word & 0x0000080000000000 ? 1 : 0), \
  (word & 0x0000040000000000 ? 1 : 0), \
  (word & 0x0000020000000000 ? 1 : 0), \
  (word & 0x0000010000000000 ? 1 : 0), \
  (word & 0x0000008000000000 ? 1 : 0), \
  (word & 0x0000004000000000 ? 1 : 0), \
  (word & 0x0000002000000000 ? 1 : 0), \
  (word & 0x0000001000000000 ? 1 : 0), \
  (word & 0x0000000800000000 ? 1 : 0), \
  (word & 0x0000000400000000 ? 1 : 0), \
  (word & 0x0000000200000000 ? 1 : 0), \
  (word & 0x0000000100000000 ? 1 : 0), \
  (word & 0x0000000080000000 ? 1 : 0), \
  (word & 0x0000000040000000 ? 1 : 0), \
  (word & 0x0000000020000000 ? 1 : 0), \
  (word & 0x0000000010000000 ? 1 : 0), \
  (word & 0x0000000008000000 ? 1 : 0), \
  (word & 0x0000000004000000 ? 1 : 0), \
  (word & 0x0000000002000000 ? 1 : 0), \
  (word & 0x0000000001000000 ? 1 : 0), \
  (word & 0x0000000000800000 ? 1 : 0), \
  (word & 0x0000000000400000 ? 1 : 0), \
  (word & 0x0000000000200000 ? 1 : 0), \
  (word & 0x0000000000100000 ? 1 : 0), \
  (word & 0x0000000000080000 ? 1 : 0), \
  (word & 0x0000000000040000 ? 1 : 0), \
  (word & 0x0000000000020000 ? 1 : 0), \
  (word & 0x0000000000010000 ? 1 : 0), \
  (word & 0x0000000000008000 ? 1 : 0), \
  (word & 0x0000000000004000 ? 1 : 0), \
  (word & 0x0000000000002000 ? 1 : 0), \
  (word & 0x0000000000001000 ? 1 : 0), \
  (word & 0x0000000000000800 ? 1 : 0), \
  (word & 0x0000000000000400 ? 1 : 0), \
  (word & 0x0000000000000200 ? 1 : 0), \
  (word & 0x0000000000000100 ? 1 : 0), \
  (word & 0x0000000000000080 ? 1 : 0), \
  (word & 0x0000000000000040 ? 1 : 0), \
  (word & 0x0000000000000020 ? 1 : 0), \
  (word & 0x0000000000000010 ? 1 : 0), \
  (word & 0x0000000000000008 ? 1 : 0), \
  (word & 0x0000000000000004 ? 1 : 0), \
  (word & 0x0000000000000002 ? 1 : 0), \
  (word & 0x0000000000000001 ? 1 : 0)

@interface GlobalFunctions : NSObject {}

// Functions
+ (unsigned long int) log2floor:(unsigned long int)n;
+ (void) write:(unsigned long int*)array
        ofSize:(unsigned long int)size
        toFile:(NSString*)filePath
        binary:(BOOL)isBinary;

+ (double) normalizedReadEnergySavingsWithS:(double)S R:(double)R CC:(double)CC r:(double)r m:(double)m p:(double)p n:(double)n h:(double)h;
+ (double) normalizedReadEnergyWithS:(double)S R:(double)R CC:(double)CC e:(double)e r:(double)r m:(double)m p:(double)p n:(double)n h:(double)h;

// THE SIX ENERGIES:
+ (double) M_readEnergyWithP:(double)p r:(double)r np:(double)np e:(double)e;
+ (double) M_writeEnergyWithP:(double)p r:(double)r np:(double)np e:(double)e S:(double)S R:(double)R;
+ (double) C_readEnergyWithP:(double)p r:(double)r np:(double)np e:(double)e S:(double)S R:(double)R;
+ (double) C_writeEnergyWithP:(double)p r:(double)r np:(double)np e:(double)e CC:(double)CC;
+ (double) H_readEnergyWithP:(double)p r:(double)r np:(double)np e:(double)e S:(double)S CC:(double)CC m:(double)m h:(double)h;
+ (double) h_writeEnergyWithP:(double)p r:(double)r np:(double)np e:(double)e S:(double)S R:(double)R CC:(double)CC m:(double)m h:(double)h;

// TOTAL ENERGIES:
+ (double) M_totalEnergyWithW:(double)w p:(double)p r:(double)r np:(double)np e:(double)e S:(double)S R:(double)R;
+ (double) C_totalEnergyWithW:(double)w p:(double)p r:(double)r np:(double)np e:(double)e S:(double)S R:(double)R CC:(double)CC;
+ (double) H_totalEnergyWithW:(double)w p:(double)p r:(double)r np:(double)np e:(double)e S:(double)S R:(double)R CC:(double)CC m:(double)m h:(double)h;

// DEACTIVATION ENERGY
+ (double) deactivationEnergyWithP:(double)p r:(double)r np:(double)np e:(double)e R:(double)R CC:(double)CC m:(double)m;

@end
