/*
 * SACache.h
 * Set Associative Cache
 *
 * Created by Miguel Lastras on Feb 19, 2015
 */

#import <Foundation/Foundation.h>
#import "InterfaceProtocol.h"

@interface SACache : NSObject <InterfaceProtocol> {
  NSString *name;
  unsigned long int sets;
  unsigned long int associativity;
  unsigned long int blockSize;
  unsigned long int capacityInBytes;
  unsigned long int setsBits;
  unsigned long int associativityBits;
  unsigned long int blockSizeBits;
  unsigned long int indexOffset;
  unsigned long int indexMask;
  unsigned long int blockAddressMask;
  unsigned long int tagOffset;
  unsigned long int accessCount;
  unsigned long int hits;
  unsigned long int misses;
  unsigned long int **tagArray;
  char memoryCapacity[32];
  id next;
}

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) unsigned long int sets;
@property (nonatomic, readonly) unsigned long int associativity;
@property (nonatomic, readonly) unsigned long int blockSize;
@property (nonatomic, readonly) unsigned long int indexOffset;
@property (nonatomic, readonly) unsigned long int indexMask;
@property (nonatomic, readonly) unsigned long int blockAddressMask;
@property (nonatomic, readonly) unsigned long int tagOffset;
@property (nonatomic) unsigned long int accessCount;
@property (nonatomic) unsigned long int hits;
@property (nonatomic) unsigned long int misses;
@property (nonatomic) unsigned long int **tagArray;

// Public interface (any cache/memory should have it)
- (void) accessBlock:(unsigned long int)address
              ofSize:(unsigned long int)size
       readOperation:(BOOL)read;

// Public interface but specific for this cache
- (id) initWithSetsBits:(unsigned long int)sb
      associativityBits:(unsigned long int)ab
      bytesPerBlockBits:(unsigned long int)bb
              nextLevel:(id)theNext
                   name:(NSString*)theName;
- (id) initWithSets:(unsigned long int)s 
      associativity:(unsigned long int)a
      bytesPerBlock:(unsigned long int)b
          nextLevel:(id)theNext
               name:(NSString*)theName;
- (void) releaseMemory;
- (void) printCapacity;

// Private interface
- (unsigned long int) insertTag:(unsigned long int)tag
                          onSet:(unsigned long int*)set;
- (BOOL) lookupTag:(unsigned long int)tag
             onSet:(unsigned long int*)set;
- (void) updateTag:(unsigned long int)tag
             onSet:(unsigned long int*)set; 
- (void) printConfiguration;
- (double) activeFraction;
@end
