/*
 * MemristiveRAM.h
 * Memristive RAM
 *
 * Created by Miguel Lastras on Apr 16, 2015
 */

#import <Foundation/Foundation.h>
#import "HHTable.h"
#import "SACache.h"
#import "GlobalDefinitions.h"


@interface MemristiveRAM : NSObject {
  NSString *name;
  HHTable *eCounters;
  SACache *memCache;
  id next;
}

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) HHTable *eCounters;
@property (nonatomic, readonly) SACache *memCache;

// Public interface
- (void) accessBlock:(unsigned long int)address
              ofSize:(unsigned long int)size
       readOperation:(BOOL)read;
- (unsigned long int) blockSize;
// Public interface but specific to MemristiveRAM
- (id) initWithSetsBits:(unsigned long int)sb
      associativityBits:(unsigned long int)ab
      bytesPerBlockBits:(unsigned long int)bb
              nextLevel:(id)theNext
                   name:(NSString*)theName;
- (void) printCapacity;
- (void) releaseMemory;
- (double) activeFraction;

@end
