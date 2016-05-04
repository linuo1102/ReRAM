/*
 * HReRAM.h
 * Hybrid Reconfigurable Resisitive RAM
 * 
 * Created by Miguel Lastras on Feb 24, 2015
 */

#import <Foundation/Foundation.h>
#import "HHTable.h"
#import "SACache.h"
#import "GlobalDefinitions.h"

@interface HReRAM : NSObject {
  NSString *name;
  HHTable *eCounters;
  SACache *memCache;
  BOOL CRSOnly;
  BOOL hybridEnabled;
  id next;
}

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) HHTable *eCounters;
@property (nonatomic, readonly) SACache *memCache;

// Public interface
- (void) accessAddress:(unsigned long int)address
         readOperation:(BOOL)read; // NEEDS UPDATE!!

// Public interface but specific to HReRAM
- (id) initWithSetsBits:(unsigned long int)sb
      associativityBits:(unsigned long int)ab
      bytesPerBlockBits:(unsigned long int)bb
              nextLevel:(id)theNext
                   name:(NSString*)theName
                CRSOnly:(BOOL)crsOnly
                 hybrid:(BOOL)hybrid;
- (void) printCapacity;
- (void) releaseMemory;
- (double) activeFraction;

@end
